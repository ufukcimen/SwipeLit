import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';
import 'phone_entry_screen.dart';
import 'package:swipelit/utils/constants.dart';

// 🌍 Country model
class CountryData {
  final String name;
  final String flag;
  final String code;

  CountryData(this.name, this.flag, this.code);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  final List<CountryData> countries = [
    CountryData("Brazil", "🇧🇷", "+55"),
    CountryData("France", "🇫🇷", "+33"),
    CountryData("Germany", "🇩🇪", "+49"),
    CountryData("India", "🇮🇳", "+91"),
    CountryData("Japan", "🇯🇵", "+81"),
    CountryData("Turkey", "🇹🇷", "+90"),
    CountryData("United Kingdom", "🇬🇧", "+44"),
    CountryData("United States", "🇺🇸", "+1"),
  ];

  late CountryData selectedCountry;

  @override
  void initState() {
    super.initState();
    countries.sort((a, b) => a.name.compareTo(b.name));
    selectedCountry = countries.firstWhere((c) => c.code == "+90");
  }

  void _openCountryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: countries.length,
        itemBuilder: (_, index) {
          final country = countries[index];
          return ListTile(
            leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
            title: Text("${country.name} (${country.code})"),
            onTap: () {
              setState(() => selectedCountry = country);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  String squeezePhone(String code, String input) {
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    return "$code$digitsOnly";
  }

  void _continueToOTP() {
    final rawPhone = phoneController.text.trim();
    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length <= 9) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Invalid Phone Number"),
          content: Text("Phone number must be longer than 10 digits."),
        ),
      );
      return;
    }

    final squeezed = squeezePhone(selectedCountry.code, rawPhone);
    Navigator.pushNamed(
      context,
      '/otpVerification',
      arguments: {
        'phoneNumber': squeezed,
        'fromSignUp': false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppPaddings.screen,
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.menu_book_rounded, size: 60, color: Colors.green),
              const SizedBox(height: 8),
              const Text("SwipeLit", style: AppTextStyles.heading),
              const SizedBox(height: 32),
              const Text(
                "Let’s start with your number",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),

              // Phone entry box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _openCountryPicker,
                      child: Row(
                        children: [
                          Text(selectedCountry.flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(selectedCountry.code, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const VerticalDivider(width: 1, thickness: 1),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter phone number",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Continue button
              GestureDetector(
                onTap: _continueToOTP,
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // OR divider
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("OR", style: TextStyle(color: Colors.black54)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 28),

              // Facebook
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(32),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    height: 64,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.facebook, color: Colors.blue, size: 28),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Login with Facebook",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 17, color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 28),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Google
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(32),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    height: 64,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Login with Google",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 17, color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 28),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // Sign up
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don’t have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/phoneEntry');
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
