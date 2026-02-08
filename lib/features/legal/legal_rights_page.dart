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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "legal_title".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 234, 245, 255),
              Color(0xFFF5FAFF),
              Colors.white,
            ],
            stops: [0.40, 0.60, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rights.length,
            itemBuilder: (context, index) {
              final right = rights[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2FCF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00695C).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    colorScheme: ColorScheme.light(
                      primary: const Color(0xFF00695C),
                    ),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      right["title"]!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gavel_outlined,
                        color: Color(0xFF00695C),
                        size: 20,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          right["description"]!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
