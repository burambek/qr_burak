import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ttn_record.dart';

class StorageService {
  static const _keyRecordsPrefix = 'ttn_records_';
  static const _keyFieldId = 'selected_field_id';
  static const _keyFieldName = 'selected_field_name';
  static const _keyLogin = 'login';
  static const _keyPassword = 'password';
  static const _keyFields = 'fields_data';
  static const _keyLastSync = 'last_sync_time';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ── Auth ──────────────────────────────────────────
  Future<void> saveCredentials(String login, String password) async {
    await _prefs.setString(_keyLogin, login);
    await _prefs.setString(_keyPassword, password);
  }

  String? getLogin() => _prefs.getString(_keyLogin);
  String? getPassword() => _prefs.getString(_keyPassword);
  bool get isLoggedIn => getLogin() != null && getLogin()!.isNotEmpty;

  Future<void> clearCredentials() async {
    await _prefs.remove(_keyLogin);
    await _prefs.remove(_keyPassword);
  }

  Future<void> logoutAndClear() async {
    await clearCredentials();
    await _prefs.remove(_keyFieldId);
    await _prefs.remove(_keyFieldName);
    // Note: We don't clear the records list here so they stay persistent for next login
  }

  // ── Fields Persistence ────────────────────────────
  Future<void> saveFields(List<Map<String, String>> fields) async {
    final encoded = jsonEncode(fields);
    await _prefs.setString(_keyFields, encoded);
  }

  List<Map<String, String>> getFields() {
    final raw = _prefs.getString(_keyFields);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, String>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Selected field ────────────────────────────────
  Future<void> saveSelectedField(String id, String name) async {
    await _prefs.setString(_keyFieldId, id);
    await _prefs.setString(_keyFieldName, name);
  }

  String? getSelectedFieldId() => _prefs.getString(_keyFieldId);
  String? getSelectedFieldName() => _prefs.getString(_keyFieldName);

  // ── Last sync timestamp ────────────────────────────
  Future<void> saveLastSyncTime(DateTime time) async {
    await _prefs.setString(_keyLastSync, time.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final raw = _prefs.getString(_keyLastSync);
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  // ── TTN Records list (User-Specific) ──────────────
  List<TtnRecord> getRecords(String? login) {
    if (login == null || login.isEmpty) return [];
    final key = '$_keyRecordsPrefix$login';
    final raw = _prefs.getStringList(key) ?? [];
    return raw
        .map((e) => TtnRecord.fromJson(jsonDecode(e)))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Future<void> saveRecord(String? login, TtnRecord record) async {
    if (login == null || login.isEmpty) return;
    final records = getRecords(login);

    final duplicate = records.any((r) => r.ttnId == record.ttnId);
    if (duplicate) throw Exception('Дублікат ТТН: ${record.ttnId}');

    records.insert(0, record);
    await _persistRecords(login, records);
  }

  // Saves without duplicate-check, used when bulk-syncing from server
  Future<void> saveRecordRaw(String login, TtnRecord record) async {
    final records = getRecords(login);
    records.insert(0, record);
    await _persistRecords(login, records);
  }

  Future<void> _persistRecords(String login, List<TtnRecord> records) async {
    final key = '$_keyRecordsPrefix$login';
    final raw = records.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(key, raw);
  }

  Future<void> clearRecords(String login) async {
    final key = '$_keyRecordsPrefix$login';
    await _prefs.remove(key);
  }
}