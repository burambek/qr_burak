import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/ttn_record.dart';
import '../services/storage_service.dart';
import '../utils/ui_helpers.dart';
import '../theme.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage;

  AppProvider(this._storage) {
    _loadFromStorage();
  }

  // ── State ─────────────────────────────────────────
  List<TtnRecord> records = [];
  List<Map<String, String>> fields = [];
  String? selectedFieldId;
  String? selectedFieldName;
  TtnRecord? pendingRecord;
  bool isLoggedIn = false;
  bool isLoading = false;
  String? errorMessage;
  int currentTabIndex = 0;

  int get scanCountLast12h {
    final twelveHoursAgo = DateTime.now().subtract(const Duration(hours: 12));
    return records.where((r) => r.dateTime.isAfter(twelveHoursAgo)).length;
  }

  // ── Init ──────────────────────────────────────────
  void _loadFromStorage() {
    isLoggedIn = _storage.isLoggedIn;
    selectedFieldId = _storage.getSelectedFieldId();
    selectedFieldName = _storage.getSelectedFieldName();
    notifyListeners();
  }

  // ── Navigation ────────────────────────────────────
  void setTab(int index) {
    currentTabIndex = index;
    if (index == 1) {
      fetchUserRecords();
    }
    notifyListeners();
  }

  // ── Auth ──────────────────────────────────────────
  Future<void> login(String login, String password) async {
    await _storage.saveCredentials(login, password);
    isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.logoutAndClear();
    isLoggedIn = false;
    selectedFieldId = null;
    selectedFieldName = null;
    records = [];
    notifyListeners();
  }

  // ── Backend API: Fetch Fields ─────────────────────
  Future<void> refreshFields() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(kApiFields),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': _storage.getLogin()}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        fields = data.map((e) => {
          'id': e['id'].toString(),
          'name': e['name'].toString(),
        }).toList();
        await _storage.saveFields(fields);
      } else {
        errorMessage = 'Помилка сервера: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'Помилка оновлення урочищ: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  // ── Backend API: Fetch Scans ──────────────────────
  Future<void> fetchUserRecords() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse(kApiList),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': _storage.getLogin()}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        records = data.map((json) => TtnRecord.fromJson(json)).toList();
      } else {
        errorMessage = 'Помилка завантаження списку: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'Помилка мережі: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  // ── QR Processing ─────────────────────────────────
  Future<bool> prepareQrRecord(String rawJson) async {
    errorMessage = null;
    if (selectedFieldId == null) {
      errorMessage = 'Оберіть урочище';
      notifyListeners();
      return false;
    }
    isLoading = true;
    notifyListeners();

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map || !decoded.containsKey('id_ttn')) {
        errorMessage = 'Невірний формат QR';
        isLoading = false;
        notifyListeners();
        return false;
      }

      final String ttnId = decoded['id_ttn'].toString();

      if (records.any((r) => r.ttnId == ttnId)) {
        errorMessage = 'ТТН $ttnId вже був сканований';
        isLoading = false;
        notifyListeners();
        return false;
      }

      // We now create the record directly from the QR data
      pendingRecord = TtnRecord(
        ttnId: ttnId,
        idCar: decoded['id_car']?.toString() ?? 'Невідомо',
        driverName: decoded['driver_name']?.toString() ?? 'Невідомо',
        fieldName: selectedFieldName!,
        fieldId: selectedFieldId!,
        dateTime: DateTime.now(),
      );

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Помилка: $e';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Backend API: Confirm Scan ─────────────────────
  Future<void> confirmRecord(BuildContext context) async {
    if (pendingRecord == null || isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(kApiSubmit),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': _storage.getLogin(),
          'id_ttn': pendingRecord!.ttnId,
          'driver_name': pendingRecord!.driverName,
          'id_car': pendingRecord!.idCar,
          'field_name': pendingRecord!.fieldName,
          'field_id': pendingRecord!.fieldId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        pendingRecord = null;
        await fetchUserRecords();
        notifyListeners();
        await UIHelpers.showStyledDialog(context, isSuccess: true, title: "Успішно");
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!context.mounted) return;
      UIHelpers.showStyledDialog(
          context,
          isSuccess: false,
          title: "Помилка",
          message: "Дані не завантажено! Перевірте інтернет."
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void cancelPendingRecord() {
    pendingRecord = null;
    notifyListeners();
  }

  void selectField(String id, String name) {
    selectedFieldId = id;
    selectedFieldName = name;
    _storage.saveSelectedField(id, name);
    notifyListeners();
  }
}