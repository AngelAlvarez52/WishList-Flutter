import 'package:flutter/material.dart';
import 'GiftsPage.dart'; // Importa el archivo gift_page.dart donde se define la página GiftPage

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
                _buildTextField("Nombre", nameController),
                const SizedBox(height: 20),
                _buildTextField("Apellido", surnameController),
                const SizedBox(height: 20),
                _buildTextField("Teléfono", phoneController),
                // Continúa agregando otros campos según sea necesario
                _buildButton(context), // Agrega el botón aquí
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
            borderSide: const BorderSide(
                color:
                    Colors.blue), // Color de la línea alrededor del TextField
          ),
          labelStyle: const TextStyle(
              color: Colors.black), // Cambia el color del texto del label
          hintStyle: const TextStyle(
              color: Colors.grey), // Cambia el color del texto del hint
        ),
        enabled: false, // Cambiar a true si quieres que sea editable.
        style: const TextStyle(
            color: Colors.black), // Cambia el color del texto del TextField
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: ElevatedButton(
        onPressed: () {
          // Navegar a la página GiftPage cuando se presiona el botón
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GiftsPage(userId: userId),
            ),
          );
        },
        child: const Text('Ver sus deseos'),
      ),
    );
  }
}
