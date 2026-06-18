import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../utils/ui_helpers.dart'; // Ensure this exists

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

  void _showFieldPicker(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Text("Оберіть урочище", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: provider.fields.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  title: Text(provider.fields[i]['name']!),
                  trailing: provider.selectedFieldId == provider.fields[i]['id']
                      ? const Icon(Icons.check, color: kGreen)
                      : null,
                  onTap: () {
                    provider.selectField(provider.fields[i]['id']!, provider.fields[i]['name']!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      final String code = barcode!.rawValue!;
      await _scannerController.stop();

      if (!mounted) return;
      final provider = context.read<AppProvider>();

      bool success = await provider.prepareQrRecord(code);

      if (success && mounted && provider.pendingRecord != null) {
        _showConfirmationDialog(context, provider);
      } else {
        if (mounted) {
          await UIHelpers.showStyledDialog(
            context,
            isSuccess: false,
            title: "Помилка",
            message: provider.errorMessage ?? "Невідома помилка",
          );
          _scannerController.start();
        }
      }
    }
  }

  void _showConfirmationDialog(BuildContext context, AppProvider provider) {
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
              const Text("Перевірка інформації", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Text("ТТН: ${provider.pendingRecord!.ttnId}\nВодій: ${provider.pendingRecord!.driverName}\nУрочище: ${provider.pendingRecord!.fieldName}"),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () {
                    provider.cancelPendingRecord();
                    _scannerController.start();
                    Navigator.pop(ctx);
                  }, child: const Text("Скасувати"))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kGreen),
                      // Update call site
                      onPressed: () {
                        provider.confirmRecord(context); // Now passing context
                        _scannerController.start();
                        Navigator.pop(ctx);
                      },
                      child: const Text("Підтвердити", style: TextStyle(color: Colors.white))
                  )),
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
        // Rounded corners for the brackets
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(20) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(20) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
        ),
        // Green lines only
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