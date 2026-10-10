import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'core/api_client.dart';
import 'services/notes_api.dart';

void main() {
  final client = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    timeout: AppConfig.requestTimeout,
  );
  runApp(NotesApp(api: NotesApi(client)));
}
