import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'RegisterPage.dart';
import 'MyHomePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Logger _logger = Logger();

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ));
  }

  Future<void> login(String email, String password) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/login');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      _logger.d('Inicio de sesión exitoso: ${data['access token']}');

      if (data.containsKey('access token')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'WishList'),
          ),
        );
      } else {
        _logger.d('Error: Token de acceso no encontrado en la respuesta.');
        _showSnackBar('Error desconocido durante el inicio de sesión.');
      }
    } else {
      _logger.d('Error de inicio de sesión: ${response.body}');

      final Map<String, dynamic> errorData = json.decode(response.body);
      if (errorData['response'] != null) {
        _showSnackBar('Usuario no existe: ${errorData['response']}');
      } else {
        _showSnackBar('Usuario no existe.');
      }
    }
  }

  void _navigateToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const RegisterPage(title: 'Registro')),
    );
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
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
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
                onPressed: () {
                  final String email = _emailController.text;
                  final String password = _passwordController.text;
                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Por favor complete todos los campos.'),
                      duration: Duration(seconds: 2),
                    ));
                  } else {
                    login(email, password);
                  }
                },
                child: const Text('Iniciar Sesión'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _navigateToRegisterPage,
                icon: const Icon(Icons.person_add),
                label: const Text('Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
