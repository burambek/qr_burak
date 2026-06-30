import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../utils/ui_helpers.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController.start();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<AppProvider>();
    if (provider.currentTabIndex == 0 && !_isProcessing) {
      _scannerController.start();
    } else {
      _scannerController.stop();
    }
  }

  void _showFieldPicker(BuildContext context, AppProvider provider) {
    String searchQuery = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filteredFields = provider.fields.where((f) =>
              (f['name'] ?? '').toLowerCase().contains(searchQuery.toLowerCase())
          ).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20
            ),
            child: Column(
              children: [
                const Text("Оберіть урочище", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Пошук урочища...",
                    prefixIcon: const Icon(Icons.search, color: kGreen),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    setModalState(() => searchQuery = val);
                  },
                ),
                const SizedBox(height: 10),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredFields.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => ListTile(
                      title: Text(filteredFields[i]['name']!),
                      trailing: provider.selectedFieldId == filteredFields[i]['id']
                          ? const Icon(Icons.check, color: kGreen)
                          : null,
                      onTap: () {
                        provider.selectField(filteredFields[i]['id']!, filteredFields[i]['name']!);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final String code = barcode!.rawValue!;

    setState(() => _isProcessing = true);
    await _scannerController.stop();

    if (!mounted) return;
    final provider = context.read<AppProvider>();

    int rez = await provider.prepareQrRecord(code);

    if (!mounted) return;

    if (rez == 1 || rez == 2 || rez == 6) {
      _showConfirmationDialog(context, provider, rez);
    } else if (rez == 3 || rez == 4 || rez == 5) {
      _showResultDialog(context, provider, rez);
    } else if (rez == -1) {
      await UIHelpers.showStyledDialog(
        context,
        isSuccess: false,
        title: "Помилка",
        message: provider.errorMessage ?? "Невірний логін або пароль",
      );
      _resumeScanning();
    } else {
      await UIHelpers.showStyledDialog(
        context,
        isSuccess: false,
        title: "Помилка",
        message: provider.errorMessage ?? "Невідома помилка",
      );
      _resumeScanning();
    }
  }

  void _resumeScanning() {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _scannerController.start();
  }

  void _showResultDialog(BuildContext context, AppProvider provider, int rez) {
    String title = "";
    String message = "";

    if (rez == 3) {
      title = "ТТН видалена";
      message = "Зверніться до логіста";
    } else if (rez == 4) {
      title = "Невірний QR-код";
      message = "ТТН не знайдено або невірний QR код";
    } else if (rez == 5) {
      title = "ТТН вже надіслано";
      message = "Ця ТТН вже була проставлена!";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFE65100)),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resumeScanning();
              },
              child: const Text("Ок"),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, AppProvider provider, int rez) {
    String confirmText = "Підтвердити";
    String infoText = "";

    if (rez == 2) {
      confirmText = "Змінити та надіслати";
      infoText = "\n* Потрібно змінити господарство!";
    } else if (rez == 6) {
      confirmText = "Змінити та надіслати";
      infoText = "\n* ТТН видане на давальника. Змінити давальника?";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(rez == 1 ? "Перевірка інформації" : "Зміна інформації",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rez == 1 ? Colors.black : const Color(0xFFE65100),
                  )),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: "ТТН: ${provider.pendingRecord?.ttnId}\n"),
                      TextSpan(text: "ID Авто: ${provider.pendingRecord?.idAvto}\n"),
                      TextSpan(text: "Авто: ${provider.pendingRecord?.idCar}\n"),
                      TextSpan(text: "Водій: ${provider.pendingRecord?.driverName}\n"),
                      TextSpan(text: "Контрагент: ${provider.pendingRecord?.kontragent}\n"),
                      TextSpan(text: "Господарство: ${provider.pendingRecord?.gosp}\n"),
                      if (infoText.isNotEmpty)
                        TextSpan(
                          text: infoText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        provider.cancelPendingRecord();
                        Navigator.pop(ctx);
                        _resumeScanning();
                      },
                      child: const Text("Скасувати"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await provider.confirmRecord(context);
                        _resumeScanning();
                      },
                      child: Text(confirmText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
          fit: BoxFit.cover,
          errorBuilder: (context, error) {
            return Center(child: Text('Помилка камери: ${error.errorCode}'));
          },
        ),

        const Align(
          alignment: Alignment.center,
          child: QrOverlay(),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: InkWell(
            onTap: () => _showFieldPicker(context, provider),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, color: kGreen),
                  const SizedBox(width: 10),
                  Expanded(child: Text(provider.selectedFieldName ?? 'Оберіть урочище')),
                  const Icon(Icons.keyboard_arrow_down)
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QrOverlay extends StatelessWidget {
  const QrOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _Corner(isTop: true, isLeft: true)),
          Positioned(top: 0, right: 0, child: _Corner(isTop: true, isLeft: false)),
          Positioned(bottom: 0, left: 0, child: _Corner(isTop: false, isLeft: true)),
          Positioned(bottom: 0, right: 0, child: _Corner(isTop: false, isLeft: false)),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _Corner({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(20) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(20) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
        ),
        border: Border(
          top: isTop ? const BorderSide(color: kGreen, width: 6) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: kGreen, width: 6) : BorderSide.none,
          left: isLeft ? const BorderSide(color: kGreen, width: 6) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: kGreen, width: 6) : BorderSide.none,
        ),
      ),
    );
  }
}