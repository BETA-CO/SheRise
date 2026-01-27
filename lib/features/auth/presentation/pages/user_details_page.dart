import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sherise/features/auth/presentation/components/my_button.dart';
import 'package:sherise/features/auth/presentation/components/my_textfield.dart';
import 'package:sherise/features/auth/presentation/pages/captcha_page.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  DateTime? selectedDate;

  void selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // Default ~18 years
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void goToPhoneAuth() {
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();

    if (name.isNotEmpty && selectedDate != null) {
      // Allow surname to be empty if optional, but user said "as option".
      // Interpret "as option" as "an option to enter surname", likely optional field?
      // Or "instead ask for surname as option" -> "ask surname instead of age".
      // Let's treat it as a standard field.
      // Name validation: Single word only
      if (name.contains(' ')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("err_single_word".tr())));
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CaptchaPage(name: name, surname: surname, dob: selectedDate!),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("err_fill_details".tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // Logo or Header
              // Image.asset('lib/assets/home page logo.png', height: 100), // Assuming this exists
              Text(
                "user_details_title".tr(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "user_details_subtitle".tr(),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Name
              MyTextfield(
                controller: nameController,
                hintText: "hint_first_name".tr(),
                obscureText: false,
              ),
              const SizedBox(height: 20),

              // Surname
              MyTextfield(
                controller: surnameController,
                hintText: "hint_surname".tr(),
                obscureText: false,
              ),
              const SizedBox(height: 20),

              // DOB Picker
              GestureDetector(
                onTap: () => selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      const SizedBox(width: 10),
                      Text(
                        selectedDate == null
                            ? "label_dob".tr()
                            : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                        style: TextStyle(
                          color: selectedDate == null
                              ? Colors.grey
                              : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              MyButton(onTap: goToPhoneAuth, text: "btn_next".tr()),
            ],
          ),
        ),
      ),
    );
  }
}
