import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'package:intl/intl.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchUserRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.fetchUserRecords(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 5,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Всього сканувань:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${provider.scanCount}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: kGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            width: double.infinity,
            color: const Color(0xFFF0F0EC),
            child: Text(
              provider.lastSyncTime != null
                  ? "Дані за ${DateFormat('dd.MM.yyyy HH:mm').format(provider.lastSyncTime!)}"
                  : "Дані ще не завантажено",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(
            child: provider.isLoading && provider.records.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.records.isEmpty
                ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(child: Text("Немає записів")),
              ],
            )
                : ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
              itemCount: provider.records.length,
              itemBuilder: (context, index) {
                final record = provider.records[index];
                final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(record.dateTime);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      "ТТН: ${record.ttnId}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Водій: ${record.driverName}\n"
                          "Авто: ${record.idCar}\n"
                          "Контрагент: ${record.kontragent}\n"
                          "Урочище: ${record.fieldName}\n"
                          "Дата: $formattedDate",
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}