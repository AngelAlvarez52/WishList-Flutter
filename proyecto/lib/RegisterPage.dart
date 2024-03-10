import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:proyecto/LoginPage.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Logger _logger = Logger();
  XFile? _image;

  Future<void> register(String name, String surname, String email, String phone,
      String password) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/Users/create');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'name': name,
        'surname': surname,
        'email': email,
        'phone': phone,
        'password': password,
        'image': _image?.path ?? '',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      _logger.d('Registro exitoso: ${data['message']}');

      // Redirige al LoginPage después de un registro exitoso
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(
              title: 'Iniciar Sesión'), // Asegúrate de pasar el título correcto
        ),
      );
    } else {
      _logger.d('Error de registro: ${response.body}');

      final Map<String, dynamic> errorData = json.decode(response.body);
      _showErrorDialog('Error: ${errorData['error']}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro"),
        backgroundColor: Colors.blue, // Color del AppBar
      ),
      body: Stack(
        children: [
          WaveWidget(
            config: CustomConfig(
              gradients: [
                [Colors.blue, Colors.blue.shade200],
                [Colors.blue.shade200, Colors.blue.shade100],
              ],
              durations: [19440, 10800],
              heightPercentages: [0.35, 0.36],
              gradientBegin: Alignment.bottomLeft,
              gradientEnd: Alignment.topRight,
            ),
            waveAmplitude: 0,
            size: const Size(double.infinity, double.infinity),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.only(
                top:
                    MediaQuery.of(context).padding.top + 0.25 * kToolbarHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Registro',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                      height: 15), // Reducción del espacio entre elementos
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 15), // Reducción del espacio entre elementos
                  TextField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      labelText: 'Apellido',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 15), // Reducción del espacio entre elementos
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 15), // Reducción del espacio entre elementos
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 15), // Reducción del espacio entre elementos
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 15), // Reducción del espacio entre elementos
                  ElevatedButton(
                    onPressed: _getImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Seleccionar imagen',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(
                      height: 15), // Reducción del espacio entre elementos
                  ElevatedButton(
                    onPressed: () {
                      final String name = _nameController.text;
                      final String surname = _surnameController.text;
                      final String email = _emailController.text;
                      final String phone = _phoneController.text;
                      final String password = _passwordController.text;
                      if (name.isEmpty ||
                          surname.isEmpty ||
                          email.isEmpty ||
                          phone.isEmpty ||
                          password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Por favor complete todos los campos.'),
                          ),
                        );
                      } else {
                        register(name, surname, email, phone, password);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Registrar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(
                      height: 15), // Reducción del espacio entre elementos
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
