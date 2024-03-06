import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:proyecto/LoginPage.dart';

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
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _surnameController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _getImage,
                child: const Text('Seleccionar imagen'),
              ),
              const SizedBox(height: 20),
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
                        content: Text('Por favor complete todos los campos.'),
                      ),
                    );
                  } else {
                    register(name, surname, email, phone, password);
                  }
                },
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
