import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ttn_record.dart';

class StorageService {
  static const _keyRecords = 'ttn_records';
  static const _keyFieldId = 'selected_field_id';
  static const _keyFieldName = 'selected_field_name';
  static const _keyLogin = 'login';
  static const _keyPassword = 'password';
  static const _keyFields = 'fields_data';

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
    await clearRecords();
  }

  // ── Fields Persistence ────────────────────────────
  Future<void> saveFields(List<Map<String, String>> fields) async {
    final encoded = jsonEncode(fields);
    await _prefs.setString(_keyFields, encoded);
  }

  List<Map<String, String>> getFields() {
    final raw = _prefs.getString(_keyFields);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => Map<String, String>.from(e)).toList();
  }

  // ── Selected field ────────────────────────────────
  Future<void> saveSelectedField(String id, String name) async {
    await _prefs.setString(_keyFieldId, id);
    await _prefs.setString(_keyFieldName, name);
  }

  String? getSelectedFieldId() => _prefs.getString(_keyFieldId);
  String? getSelectedFieldName() => _prefs.getString(_keyFieldName);

  // ── TTN Records list ──────────────────────────────
  List<TtnRecord> getRecords() {
    final raw = _prefs.getStringList(_keyRecords) ?? [];
    return raw
        .map((e) => TtnRecord.fromJson(jsonDecode(e)))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Future<void> saveRecord(TtnRecord record) async {
    final records = getRecords();

    final duplicate = records.any((r) => r.ttnId == record.ttnId);
    if (duplicate) return;

    records.insert(0, record);
    await _persistRecords(records);
  }

  Future<void> updateRecordStatus(String id, TtnStatus status) async {
    final records = getRecords();
    final index = records.indexWhere((r) => r.id == id);
    if (index != -1) {
      records[index].status = status;
      await _persistRecords(records);
    }
  }

  Future<void> _persistRecords(List<TtnRecord> records) async {
    final raw = records.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(_keyRecords, raw);
  }

  Future<void> clearRecords() async {
    await _prefs.remove(_keyRecords);
  }
}