import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../utils/ui_helpers.dart';
import 'scanner_screen.dart';
import 'list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      extendBody: true, // IMPORTANT: Allows body to extend behind bottom nav
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', height: 40),
        actions: [
          if (provider.currentTabIndex == 0)
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => _onRefresh(context)),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AppProvider>().logout()),
        ],
      ),
      // Use a Stack to place the Nav Bar ON TOP of the body
      body: Stack(
        children: [
          IndexedStack(
            index: provider.currentTabIndex,
            children: const [ScannerScreen(), ListScreen()],
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: const Color(0xFF4A4A4A).withValues(alpha: 0.9), // Added opacity for camera view
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _buildNavItem(context, Icons.qr_code_scanner, 'Сканувати', 0, provider.currentTabIndex == 0),
                  _buildNavItem(context, Icons.list, 'Список', 1, provider.currentTabIndex == 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, bool isActive) {
    return Expanded(
      child: InkWell(
        onTap: () => context.read<AppProvider>().setTab(index),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: isActive ? BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(16)) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? Colors.white : Colors.grey),
              Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRefresh(BuildContext context) async {
    final provider = context.read<AppProvider>();
    await provider.refreshFields();
    if (!context.mounted) return;
    
    await UIHelpers.showStyledDialog(
      context, 
      isSuccess: provider.errorMessage == null, 
      title: provider.errorMessage == null ? "Успішно оновлено" : "Помилка",
      message: provider.errorMessage,
    );
  }
}