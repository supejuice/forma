import 'dart:io';

import 'package:dio/dio.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stdout.writeln(
      'Usage: dart run tool/mistral_dio_check.dart <mistral_api_key>',
    );
    exit(64);
  }

  final String apiKey = arguments.first.trim();
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final Stopwatch sw = Stopwatch()..start();
  try {
    final Response<Map<String, dynamic>> response = await dio
        .get<Map<String, dynamic>>(
          'https://api.mistral.ai/v1/models',
          options: Options(
            headers: <String, String>{'Authorization': 'Bearer $apiKey'},
          ),
        );
    stdout.writeln('status=${response.statusCode} elapsed=${sw.elapsed}');
  } catch (error) {
    stdout.writeln('error=$error elapsed=${sw.elapsed}');
    exit(1);
  }
}
