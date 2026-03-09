import 'dart:async';
import 'dart:collection';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'proto/common.pb.dart' as otel_common;
import 'proto/logs.pb.dart' as otel_logs;
import 'proto/logs_service.pb.dart' as otel_service;
import 'proto/logs_service.pbgrpc.dart' as otel_grpc;
import 'proto/resource.pb.dart' as otel_resource;

const _maxBufferSize = 100;
const _flushInterval = Duration(seconds: 2);

/// Batches OTLP log records and exports them via gRPC.
class LogExporter {
  LogExporter({
    required String endpoint,
    required String serviceName,
    String? serviceVersion,
    bool insecure = true,
  }) {
    final parts = endpoint.split(':');
    final host = parts.first;
    final port = parts.length > 1 ? int.parse(parts[1]) : 4317;

    _channel = ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        credentials: insecure
            ? const ChannelCredentials.insecure()
            : const ChannelCredentials.secure(),
      ),
    );
    _client = otel_grpc.LogsServiceClient(_channel);

    _resource = otel_resource.Resource(
      attributes: [
        otel_common.KeyValue(
          key: 'service.name',
          value: otel_common.AnyValue(stringValue: serviceName),
        ),
        if (serviceVersion != null)
          otel_common.KeyValue(
            key: 'service.version',
            value: otel_common.AnyValue(stringValue: serviceVersion),
          ),
      ],
    );

    _timer = Timer.periodic(_flushInterval, (_) => _flush());
  }

  late final ClientChannel _channel;
  late final otel_grpc.LogsServiceClient _client;
  late final otel_resource.Resource _resource;
  late final Timer _timer;

  final _buffer = Queue<_BufferedRecord>();
  bool _shuttingDown = false;

  /// Enqueues a log record for export.
  void add({
    required Int64 timeUnixNano,
    required otel_logs.SeverityNumber severityNumber,
    required String severityText,
    required String body,
    required String scopeName,
    required List<otel_common.KeyValue> attributes,
  }) {
    if (_shuttingDown) return;

    _buffer.add(
      _BufferedRecord(
        timeUnixNano: timeUnixNano,
        severityNumber: severityNumber,
        severityText: severityText,
        body: body,
        scopeName: scopeName,
        attributes: attributes,
      ),
    );

    if (_buffer.length >= _maxBufferSize) {
      _flush();
    }
  }

  /// Flushes buffered records and closes the gRPC channel.
  Future<void> shutdown() async {
    _shuttingDown = true;
    _timer.cancel();
    await _flush();
    await _channel.shutdown();
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;

    // Drain buffer into a local list.
    final records = <_BufferedRecord>[];
    while (_buffer.isNotEmpty) {
      records.add(_buffer.removeFirst());
    }

    // Group records by scope name.
    final byScope = <String, List<otel_logs.LogRecord>>{};
    for (final r in records) {
      (byScope[r.scopeName] ??= []).add(
        otel_logs.LogRecord(
          timeUnixNano: r.timeUnixNano,
          observedTimeUnixNano: r.timeUnixNano,
          severityNumber: r.severityNumber,
          severityText: r.severityText,
          body: otel_common.AnyValue(stringValue: r.body),
          attributes: r.attributes,
        ),
      );
    }

    final scopeLogs = byScope.entries.map((e) {
      return otel_logs.ScopeLogs(
        scope: otel_common.InstrumentationScope(name: e.key),
        logRecords: e.value,
      );
    });

    final request = otel_service.ExportLogsServiceRequest(
      resourceLogs: [
        otel_logs.ResourceLogs(resource: _resource, scopeLogs: scopeLogs),
      ],
    );

    try {
      await _client.export(request);
    } catch (_) {
      // Silently drop — never block or crash the app.
    }
  }
}

class _BufferedRecord {
  const _BufferedRecord({
    required this.timeUnixNano,
    required this.severityNumber,
    required this.severityText,
    required this.body,
    required this.scopeName,
    required this.attributes,
  });

  final Int64 timeUnixNano;
  final otel_logs.SeverityNumber severityNumber;
  final String severityText;
  final String body;
  final String scopeName;
  final List<otel_common.KeyValue> attributes;
}
