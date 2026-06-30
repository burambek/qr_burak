import 'dart:convert';
import 'dart:async';
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

  final bool _isTestMode = false;

  // ── State ─────────────────────────────────────────
  List<TtnRecord> records = [];
  List<Map<String, String>> fields = [];
  String? selectedFieldId;
  String? selectedFieldName;
  TtnRecord? pendingRecord;
  Map<String, dynamic>? lastScanData;
  DateTime? lastSyncTime;
  bool isLoggedIn = false;
  bool isLoading = false;
  String? errorMessage;
  int currentTabIndex = 0;

  int get scanCount => records.length;

  // ── Init ──────────────────────────────────────────
  void _loadFromStorage() {
    isLoggedIn = _storage.isLoggedIn;
    final login = _storage.getLogin();
    records = _storage.getRecords(login);
    fields = _storage.getFields();
    selectedFieldId = _storage.getSelectedFieldId();
    selectedFieldName = _storage.getSelectedFieldName();
    lastSyncTime = _storage.getLastSyncTime();
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
  Future<bool> login(String login, String password) async {
    if (login.trim().isEmpty || password.trim().isEmpty) {
      errorMessage = 'Введіть логін та пароль';
      notifyListeners();
      return false;
    }

    await _storage.saveCredentials(login.trim(), password.trim());
    isLoggedIn = true;
    records = _storage.getRecords(login.trim());
    fields = _storage.getFields();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _storage.logoutAndClear();
    isLoggedIn = false;
    selectedFieldId = null;
    selectedFieldName = null;
    records = [];
    fields = [];
    notifyListeners();
  }

  // ── Backend API: Fetch Fields ─────────────────────
  Future<void> refreshFields() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final login = _storage.getLogin() ?? '';
      final password = _storage.getPassword() ?? '';

      final response = await http.post(
        Uri.parse(kApiGetFields),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': login, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          fields = decoded.map((e) {
            final map = e as Map<dynamic, dynamic>;
            return {
              'id': (map['kod'] ?? '').toString(),
              'name': (map['name'] ?? '').toString(),
            };
          }).where((f) => f['id']!.isNotEmpty)
              .toList()
              .cast<Map<String, String>>();

          await _storage.saveFields(fields);

          if (selectedFieldId != null) {
            final exists = fields.any((f) => f['id'] == selectedFieldId);
            if (!exists) {
              selectedFieldId = null;
              selectedFieldName = null;
            }
          }
        }
      } else {
        errorMessage = 'Сервер повернув помилку: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'Помилка оновлення: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Backend API: Fetch Scans (overwrites local storage) ──
  Future<void> fetchUserRecords() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final login = _storage.getLogin() ?? '';
      final password = _storage.getPassword() ?? '';

      debugPrint('fetchUserRecords: calling $kApiListTTN with login=$login');

      final response = await http.post(
        Uri.parse(kApiListTTN),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': login, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      debugPrint('fetchUserRecords status: ${response.statusCode}');
      debugPrint('fetchUserRecords body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          debugPrint('fetchUserRecords: got ${decoded.length} raw items');
          records = decoded
              .map((json) => TtnRecord.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          debugPrint('fetchUserRecords: parsed ${records.length} records');

          await _storage.clearRecords(login);
          for (final r in records) {
            await _storage.saveRecordRaw(login, r);
          }

          lastSyncTime = DateTime.now();
          await _storage.saveLastSyncTime(lastSyncTime!);
        } else {
          debugPrint('fetchUserRecords: decoded is NOT a List, type=${decoded.runtimeType}');
        }
      } else {
        debugPrint('Fetch List Error: ${response.statusCode}');
        records = _storage.getRecords(login);
      }
    } catch (e, stack) {
      debugPrint('Fetch List Exception: $e');
      debugPrint('Stack: $stack');
      records = _storage.getRecords(_storage.getLogin());
    }

    isLoading = false;
    notifyListeners();
  }

  // ── QR Processing ─────────────────────────────────
  Future<int> prepareQrRecord(String rawJson) async {
    errorMessage = null;
    pendingRecord = null;
    lastScanData = null;

    if (selectedFieldId == null || selectedFieldName == null) {
      errorMessage = 'Оберіть урочище';
      notifyListeners();
      return 0;
    }

    isLoading = true;
    notifyListeners();

    try {
      String ttnId = rawJson.trim();
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map && decoded.containsKey('id_ttn')) {
          ttnId = decoded['id_ttn']?.toString() ?? ttnId;
        }
      } catch (_) {}

      if (_isTestMode) {
        // simulation code placeholder
      }

      final response = await http.post(
        Uri.parse(kApiGetTTN),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': _storage.getLogin() ?? '',
          'password': _storage.getPassword() ?? '',
          'id_ttn': ttnId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final data = Map<String, dynamic>.from(decoded);
          return _processApiResponse(data, ttnId);
        } else {
          errorMessage = 'Невірний формат відповіді сервера';
        }
      } else {
        errorMessage = 'Помилка сервера: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'Помилка: $e';
    }

    isLoading = false;
    notifyListeners();
    return 0;
  }

  int _processApiResponse(Map<String, dynamic> data, String ttnId) {
    lastScanData = data;

    if (data['access']?.toString() != '+') {
      errorMessage =
      'Не правильний Логін або Пароль. \nПеревірте дані або зверніться до логіста.';
      isLoading = false;
      notifyListeners();
      return -1;
    }

    final int rez = int.tryParse(data['rez']?.toString() ?? '0') ?? 0;

    if (rez == 1 || rez == 2 || rez == 6) {
      pendingRecord = TtnRecord(
        ttnId: (data['nomer'] ?? ttnId).toString(),
        qrData: ttnId,
        idCar: (data['avto'] ?? 'Невідомо').toString(),
        driverName: (data['driver'] ?? 'Невідомо').toString(),
        idAvto: (data['id_avto'] ?? '').toString(),
        kontragent: (data['kontragent'] ?? '').toString(),
        gosp: (data['gosp'] ?? '').toString(),
        fieldName: selectedFieldName ?? 'Невідомо',
        fieldId: selectedFieldId ?? '0',
        dateTime: DateTime.now(),
        rez: rez,
      );
    }

    isLoading = false;
    notifyListeners();
    return rez;
  }

  // ── Backend API: Send TTN to Server ───────────────
  Future<void> confirmRecord(BuildContext context) async {
    if (pendingRecord == null || isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      final login = _storage.getLogin() ?? '';
      final password = _storage.getPassword() ?? '';

      final response = await http.post(
        Uri.parse(kApiWriteTTN),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': login,
          'password': password,
          'id_field': pendingRecord!.fieldId,
          'rez': pendingRecord!.rez.toString(),
          'id_ttn': pendingRecord!.qrData,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('confirmRecord status: ${response.statusCode}');
      debugPrint('confirmRecord body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final String rezResult = decoded['rez']?.toString() ?? '';

        if (rezResult == '+') {
          await _storage.saveRecord(login, pendingRecord!);
          pendingRecord = null;
          records = _storage.getRecords(login);

          notifyListeners();
          if (!context.mounted) return;
          await UIHelpers.showStyledDialog(context,
              isSuccess: true, title: "Успішно надіслано");
        } else {
          throw Exception('Сервер відхилив запис: $rezResult');
        }
      } else {
        throw Exception('Сервер повернув помилку: ${response.statusCode}');
      }
    } catch (e) {
      if (!context.mounted) return;
      UIHelpers.showStyledDialog(
        context,
        isSuccess: false,
        title: "Помилка",
        message: "Не вдалося надіслати дані: $e",
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