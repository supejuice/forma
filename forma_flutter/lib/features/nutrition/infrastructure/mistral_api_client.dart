import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_exception.dart';
import '../domain/mistral_usage_ledger.dart';

final Provider<MistralApiClient> mistralApiClientProvider =
    Provider<MistralApiClient>(
      (Ref ref) => MistralApiClient(
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 30),
          ),
        ),
      ),
    );

class MistralApiClient {
  MistralApiClient(this._dio);

  static const String _baseUrl = 'https://api.mistral.ai/v1';

  final Dio _dio;

  Future<ChatCompletionResult> chatCompletions({
    required String apiKey,
    required List<Map<String, String>> messages,
    String model = 'mistral-small-latest',
  }) async {
    final Options options = Options(
      headers: <String, Object>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    try {
      final Response<Map<String, dynamic>> response = await _dio
          .post<Map<String, dynamic>>(
            '$_baseUrl/chat/completions',
            options: options,
            data: <String, Object>{
              'model': model,
              'temperature': 0.2,
              'response_format': <String, String>{'type': 'json_object'},
              'messages': messages,
            },
          );
      return ChatCompletionResult(
        content: _extractMessageContent(response.data),
        usage: _extractUsage(response.data),
      );
    } on DioException catch (error) {
      if (_looksLikeUnsupportedResponseFormat(error)) {
        final Response<Map<String, dynamic>> fallbackResponse = await _dio
            .post<Map<String, dynamic>>(
              '$_baseUrl/chat/completions',
              options: options,
              data: <String, Object>{
                'model': model,
                'temperature': 0.2,
                'messages': messages,
              },
            );
        return ChatCompletionResult(
          content: _extractMessageContent(fallbackResponse.data),
          usage: _extractUsage(fallbackResponse.data),
        );
      }
      throw _apiExceptionFromDio(error);
    }
  }

  Future<void> validateKey(String apiKey) async {
    try {
      await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/models',
        options: Options(
          headers: <String, Object>{'Authorization': 'Bearer $apiKey'},
        ),
      );
    } on DioException catch (error) {
      throw _apiExceptionFromDio(error);
    }
  }

  AppException _apiExceptionFromDio(DioException error) {
    final Response<dynamic>? response = error.response;
    if (response == null) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return const AppException(
          'Request to Mistral timed out. Check internet connection and retry.',
        );
      }

      if (kIsWeb && _looksLikeBrowserBlockedRequest(error)) {
        return const AppException(
          'Browser blocked direct connection to Mistral. Use Save Without Check, or route Mistral calls through a backend proxy.',
        );
      }

      return const AppException(
        'Unable to reach Mistral right now. Check internet connection and retry.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      return const AppException(
        'Mistral API key is invalid or lacks permissions.',
      );
    }

    final String serverMessage = _extractErrorMessage(response.data);
    if (serverMessage.isNotEmpty) {
      return AppException(serverMessage);
    }

    return AppException('Mistral request failed (${response.statusCode}).');
  }

  bool _looksLikeBrowserBlockedRequest(DioException error) {
    if (error.type != DioExceptionType.connectionError) {
      return false;
    }
    final String message =
        '${error.message ?? ''} ${error.error ?? ''}'.toLowerCase();
    return message.contains('xmlhttprequest') || message.contains('cors');
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final dynamic message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      final dynamic error = data['error'];
      if (error is Map<String, dynamic>) {
        final dynamic nestedMessage = error['message'];
        if (nestedMessage is String && nestedMessage.isNotEmpty) {
          return nestedMessage;
        }
      }
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return '';
  }

  bool _looksLikeUnsupportedResponseFormat(DioException error) {
    if (error.response?.statusCode != 400) {
      return false;
    }
    final String payload = jsonEncode(error.response?.data);
    return payload.contains('response_format');
  }

  MistralTokenUsage? _extractUsage(Map<String, dynamic>? payload) {
    if (payload == null) {
      return null;
    }
    final dynamic usageValue = payload['usage'];
    if (usageValue is Map<String, dynamic>) {
      final MistralTokenUsage usage = MistralTokenUsage.fromJson(usageValue);
      return usage.totalTokens > 0 ? usage : null;
    }
    if (usageValue is Map<dynamic, dynamic>) {
      final MistralTokenUsage usage = MistralTokenUsage.fromJson(
        usageValue.cast<String, dynamic>(),
      );
      return usage.totalTokens > 0 ? usage : null;
    }
    return null;
  }

  String _extractMessageContent(Map<String, dynamic>? payload) {
    if (payload == null) {
      throw const AppException('Mistral returned an empty response.');
    }

    final dynamic choicesValue = payload['choices'];
    if (choicesValue is! List<dynamic> || choicesValue.isEmpty) {
      throw const AppException('Mistral did not return completion choices.');
    }

    final dynamic choice = choicesValue.first;
    if (choice is! Map<String, dynamic>) {
      throw const AppException('Unexpected completion payload shape.');
    }

    final dynamic message = choice['message'];
    if (message is! Map<String, dynamic>) {
      throw const AppException(
        'Completion message missing from Mistral response.',
      );
    }

    final dynamic content = message['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content;
    }
    if (content is List<dynamic>) {
      final StringBuffer buffer = StringBuffer();
      for (final dynamic block in content) {
        if (block is Map<String, dynamic>) {
          final dynamic text = block['text'];
          if (text is String) {
            buffer.write(text);
          }
        } else if (block is String) {
          buffer.write(block);
        }
      }
      final String resolved = buffer.toString().trim();
      if (resolved.isNotEmpty) {
        return resolved;
      }
    }

    throw const AppException('Mistral returned an empty completion payload.');
  }
}

class ChatCompletionResult {
  const ChatCompletionResult({required this.content, this.usage});

  final String content;
  final MistralTokenUsage? usage;
}
