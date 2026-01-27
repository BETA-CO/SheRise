import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LegalRightsPage extends StatelessWidget {
  const LegalRightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> rights = [
      {
        "title": "right_zero_fir".tr(),
        "description": "right_desc_zero_fir".tr(),
      },
      {"title": "right_privacy".tr(), "description": "right_desc_privacy".tr()},
      {"title": "right_sunset".tr(), "description": "right_desc_sunset".tr()},
      {"title": "right_digital".tr(), "description": "right_desc_digital".tr()},
      {
        "title": "right_domestic".tr(),
        "description": "right_desc_domestic".tr(),
      },
      {
        "title": "right_legal_aid".tr(),
        "description": "right_desc_legal_aid".tr(),
      },
      {
        "title": "right_equal_pay".tr(),
        "description": "right_desc_equal_pay".tr(),
      },
    ];

    return Scaffold(
      appBar: AppBar(title: Text("legal_title".tr())),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rights.length,
        itemBuilder: (context, index) {
          final right = rights[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                right["title"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              leading: const Icon(Icons.gavel, color: Colors.purple),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    right["description"]!,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
