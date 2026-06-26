import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pocketbase_drift/pocketbase_drift.dart';

class PocketBaseService {
  static late PocketBase client;

  static Future<void> init() async {
    if (kIsWeb) {
      client = PocketBase('https://simplekennel.pockethost.io/');
    } else {
      client = $PocketBase.database('https://simplekennel.pockethost.io/');
    }
  }

  static bool get isLoggedIn => client.authStore.isValid;

  static Future<void> login(String email, String password) async {
    await client.collection('_superusers').authWithPassword(email, password);
  }

  static void logout() => client.authStore.clear();
}
