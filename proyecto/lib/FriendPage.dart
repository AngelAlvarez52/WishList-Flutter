import 'package:flutter/material.dart';

class FriendPage extends StatelessWidget {
  final int userId; // Suponiendo que el ID es un entero
  final String userImageUrl;
  final TextEditingController nameController;
  final TextEditingController surnameController;
  final TextEditingController emailController; // Si decides usarlo
  final TextEditingController phoneController;

  const FriendPage({
    Key? key,
    required this.userId, // Asegúrate de pasar el ID aquí
    required this.userImageUrl,
    required this.nameController,
    required this.surnameController,
    required this.emailController,
    required this.phoneController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
      ),
      body: Container(
        constraints: const BoxConstraints.expand(), // Expande el Container
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(userImageUrl),
                    radius: 50,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField("", nameController),
                const SizedBox(height: 20),
                _buildTextField("", surnameController),
                const SizedBox(height: 20),
                _buildTextField("", phoneController),
                // Continúa agregando otros campos según sea necesario
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 20.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        enabled: false, // Cambiar a true si quieres que sea editable.
      ),
    );
  }
}
