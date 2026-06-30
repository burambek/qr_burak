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
                isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
                color: isSuccess ? Colors.green : const Color(0xFFE65100),
                size: 60,
              ),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.black : const Color(0xFFE65100),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(
                  message, 
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSuccess ? Colors.black : const Color(0xFFE65100),
                  ),
                ),
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
