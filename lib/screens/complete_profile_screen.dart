import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../main.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final FirestoreService firestoreService = FirestoreService();

  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController dobController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  final TextEditingController emergency1Controller = TextEditingController();

  final TextEditingController emergency2Controller = TextEditingController();

  final TextEditingController emergency3Controller = TextEditingController();
  File? profileImage;

  final ImagePicker picker = ImagePicker();
  String? selectedGender;

  String? selectedNationality;

  final List<String> genders = ["Male", "Female", "Other"];

  final List<String> nationalities = [
    "India",
    "United States",
    "United Kingdom",
    "Canada",
    "Australia",
    "Germany",
    "France",
    "Japan",
    "Nepal",
    "Sri Lanka",
    "Bangladesh",
  ];
  @override
  void initState() {
    super.initState();

    phoneController.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? "";
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dobController.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  void showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool validateForm() {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        dobController.text.isEmpty ||
        addressController.text.isEmpty ||
        selectedGender == null ||
        selectedNationality == null ||
        emergency1Controller.text.isEmpty) {
      return false;
    }

    return true;
  }

  Future<void> saveProfile() async {
    if (!validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final user = UserModel(
      uid: FirebaseAuth.instance.currentUser!.uid,
      fullName: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      dob: dobController.text.trim(),
      gender: selectedGender!,
      nationality: selectedNationality!,
      address: addressController.text.trim(),
      profileImage: "",
      emergencyContact1: emergency1Controller.text.trim(),
      emergencyContact2: emergency2Controller.text.trim(),
      emergencyContact3: emergency3Controller.text.trim(),
      profileCompleted: true,
    );
    print("SAVE BUTTON CLICKED");

    try {
      print("Saving user...");

      await firestoreService.saveUser(user);

      print("User Saved");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile saved successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
        (route) => false,
      );
    } catch (e) {
      print("FIRESTORE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 20),

              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          profileImage != null
                              ? FileImage(profileImage!)
                              : null,
                      child:
                          profileImage == null
                              ? const Icon(
                                Icons.person,
                                size: 55,
                                color: Colors.grey,
                              )
                              : null,
                    ),

                    Positioned(
                      bottom: 0,

                      right: 0,

                      child: CircleAvatar(
                        radius: 18,

                        backgroundColor: Colors.blue,

                        child: IconButton(
                          padding: EdgeInsets.zero,

                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),

                          onPressed: showImagePicker,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Center(
                child: Text(
                  "Complete Your Profile",

                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  "Let's make your travel experience\nsafe and secure.",

                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 35),
              buildTextField(
                hint: "Full Name",
                icon: Icons.person,
                controller: nameController,
              ),

              buildTextField(
                hint: "Email Address",
                icon: Icons.email,
                controller: emailController,
              ),

              buildTextField(
                hint: "Phone Number",
                icon: Icons.phone,
                controller: phoneController,
                readOnly: true,
              ),

              buildTextField(
                hint: "Date of Birth",
                icon: Icons.cake,
                controller: dobController,
                readOnly: true,
                onTap: pickDate,
              ),

              buildTextField(
                hint: "Full Address",
                icon: Icons.home,
                controller: addressController,
              ),
              buildDropdown(
                hint: "Select Gender",
                icon: Icons.people,
                items: genders,
                value: selectedGender,
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
              ),

              buildDropdown(
                hint: "Select Nationality",
                icon: Icons.public,
                items: nationalities,
                value: selectedNationality,
                onChanged: (value) {
                  setState(() {
                    selectedNationality = value;
                  });
                },
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 12, top: 8),
                child: Text(
                  "Emergency Contacts",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              buildTextField(
                hint: "Emergency Contact 1",
                icon: Icons.contact_phone,
                controller: emergency1Controller,
              ),

              buildTextField(
                hint: "Emergency Contact 2",
                icon: Icons.contact_phone,
                controller: emergency2Controller,
              ),

              buildTextField(
                hint: "Emergency Contact 3",
                icon: Icons.contact_phone,
                controller: emergency3Controller,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Save & Continue",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),

          hintText: hint,

          filled: true,

          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget buildDropdown({
    required String hint,
    required IconData icon,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        items:
            items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
