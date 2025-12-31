import 'package:flutter/material.dart';

class LegalRightsPage extends StatelessWidget {
  const LegalRightsPage({super.key});

  final List<Map<String, String>> rights = const [
    {
      "title": "Zero FIR",
      "description":
          "A woman can file an FIR at any police station, irrespective of where the incident occurred. The police must register it and transfer it to the relevant station later.",
    },
    {
      "title": "Right to Privacy",
      "description":
          "Under Section 228A of the IPC, the identity of a rape victim cannot be disclosed by the police or media. She can record her statement alone or in the presence of a female officer.",
    },
    {
      "title": "No Arrest After Sunset",
      "description":
          "According to the CrPC, a woman cannot be arrested after sunset and before sunrise, except in exceptional circumstances and with a magistrate's order.",
    },
    {
      "title": "Digital Harassment",
      "description":
          "Under the IT Act, cyberstalking, voyeurism, and harassment via email or social media are punishable offenses. You can report these to the Cyber Crime Cell.",
    },
    {
      "title": "Domestic Violence Act",
      "description":
          "The Protection of Women from Domestic Violence Act, 2005, protects women from physical, emotional, sexual, and economic abuse by a partner or family member.",
    },
    {
      "title": "Free Legal Aid",
      "description":
          "Women are entitled to free legal aid under the Legal Services Authorities Act, ensuring they can access justice regardless of their financial status.",
    },
    {
      "title": "Right to equal pay",
      "description":
          "According to the Equal Remuneration Act, women have a right to equal pay for equal work.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Legal Rights & Awareness")),
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
