import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'RegisterPage.dart';
import 'MyHomePage.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isRememberMeChecked = false;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadRememberMeState();
  }

  void _loadRememberMeState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    setState(() {
      _isRememberMeChecked = prefs.getBool('rememberMe') ?? false;
      if (_isRememberMeChecked && isLoggedIn) {
        final String email = prefs.getString('email') ?? '';
        final String password = prefs.getString('password') ?? '';
        if (email.isNotEmpty && password.isNotEmpty) {
          _emailController.text = email;
          _passwordController.text = password;
          login(email, password);
        }
      }
    });
  }

  void _saveRememberMeState(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
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

      if (data.containsKey('access token')) {
        _logger.d('Login successful: ${data['access token']}');

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', data['access token']);
        await prefs.setString('email', email);
        await prefs.setString('password', password);
        await prefs.setBool('isLoggedIn', true);

        if (_isRememberMeChecked) {
          await prefs.setBool('rememberMe', true);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyHomePage(
                  title: 'WishList', authToken: data['access token']),
            ),
          );
          _clearFields(); // Limpia los campos después del login exitoso
        }
      } else {
        _showSnackBar('Unknown error during login.');
      }
    } else {
      _showSnackBar('Login failed.');
    }
  }

  void _navigateToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const RegisterPage(title: 'Register')),
    );
  }

  void _clearFields() {
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _isRememberMeChecked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
              heightPercentages: [0.20, 0.25],
              gradientBegin: Alignment.bottomLeft,
              gradientEnd: Alignment.topRight,
            ),
            waveAmplitude: 0,
            size: const Size(double.infinity, double.infinity),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                  ),
                ),
                CheckboxListTile(
                  title: const Text("Mantener sesion iniciada"),
                  value: _isRememberMeChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isRememberMeChecked = value ?? false;
                      _saveRememberMeState(_isRememberMeChecked);
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final String email = _emailController.text.trim();
                    final String password = _passwordController.text.trim();
                    if (email.isEmpty || password.isEmpty) {
                      _showSnackBar('Please fill in all fields.');
                    } else {
                      login(email, password);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Login',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _navigateToRegisterPage,
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text('Register',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
