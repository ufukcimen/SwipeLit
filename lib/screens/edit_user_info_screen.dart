import 'package:flutter/material.dart';
import '../utils/constants.dart';

class EditUserInfoScreen extends StatefulWidget {
  const EditUserInfoScreen({super.key});

  @override
  State<EditUserInfoScreen> createState() => _EditUserInfoScreenState();
}

class _EditUserInfoScreenState extends State<EditUserInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = "Yağız";
  String age = "21";
  String bio = "Bio.";
  String gender = "Other";

  final List<String> genderOptions = ["Male", "Female", "Other"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Info'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage("https://i.imgur.com/BoN9kdC.png"),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 18),
                    onPressed: () {
                      // Optional: Add image picker logic later
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Form Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (val) => name = val ?? '',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (val) => age = val ?? '',
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: gender,
                    items: genderOptions
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) => setState(() => gender = val!),
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: bio,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      prefixIcon: Icon(Icons.edit_note),
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (val) => bio = val ?? '',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          ElevatedButton.icon(
            onPressed: () {
              _formKey.currentState?.save();

              // TODO: Save to database or service
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Changes saved!")),
              );

              print("Name: $name, Age: $age, Gender: $gender, Bio: $bio");
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
