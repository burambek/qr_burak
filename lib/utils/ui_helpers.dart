// lib/utils/ui_helpers.dart
import 'package:flutter/material.dart';

class UIHelpers {
  static Future<void> showStyledDialog(BuildContext context,
      {required bool isSuccess, required String title, String? message}) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel,
                color: isSuccess ? Colors.green : Colors.red,
                size: 60,
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Ок"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
