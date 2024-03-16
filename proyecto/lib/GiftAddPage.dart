import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

class GiftAddPage extends StatefulWidget {
  final String authToken;

  const GiftAddPage({Key? key, required this.authToken}) : super(key: key);

  @override
  GiftAddPageState createState() => GiftAddPageState();
}

class GiftAddPageState extends State<GiftAddPage> {
  late Future<int> _userIdFuture;
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  final Logger _logger = Logger();
  String? _imageUrl;
  int? _selectedCategoryId;
  int? _selectedShopId;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _shops = [];

  @override
  void initState() {
    super.initState();
    _userIdFuture = _getUserId();
    _fetchCategories();
    _fetchShops();
  }

  Future<int> _getUserId() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/userprofile'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
      },
    );
    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      return userData['id'];
    } else {
      throw Exception('Failed to get user id');
    }
  }

  Future<void> _fetchCategories() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/api/categories'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _categories =
            data.map((category) => category as Map<String, dynamic>).toList();
      });
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> _fetchShops() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/api/Shops'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _shops = data.map((shop) => shop as Map<String, dynamic>).toList();
      });
    } else {
      throw Exception('Failed to load shops');
    }
  }

  Future<void> _addGift() async {
    final userId = await _userIdFuture;
    final url = Uri.parse('http://127.0.0.1:8000/api/Gifts/create');

    final request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer ${widget.authToken}',
    });

    request.fields['name'] = nameController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['url'] = urlController.text;
    request.fields['price'] = priceController.text;
    request.fields['category_id'] = _selectedCategoryId.toString();
    request.fields['user_id'] = userId.toString();
    request.fields['shop_id'] = _selectedShopId.toString();

    // Adjuntar la imagen al formulario
    if (_imageUrl != null) {
      request.fields['image'] = _imageUrl!;
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      _logger.i('Gift added successfully');
      _logger.i(await response.stream.bytesToString());

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Felicidades, agregaste un nuevo deseo'),
        ),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context,
          true); // Regresar a la página anterior y notificar que se agregó un regalo
    } else {
      _logger.e('Failed to add gift');
      _logger.e(await response.stream.bytesToString());
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageUrl = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Regalo'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descripcion'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Precio'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Subir Imagen'),
              ),
              const SizedBox(height: 16),
              if (_imageUrl != null)
                Image.network(
                  _imageUrl!,
                  height: 200,
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategoryId = newValue;
                  });
                },
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Escoge una categoría'),
                  ),
                  for (final category in _categories)
                    DropdownMenuItem<int>(
                      value: category['id'],
                      child: Text(category['name']),
                    )
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedShopId,
                onChanged: (newValue) {
                  setState(() {
                    _selectedShopId = newValue;
                  });
                },
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Escoge una tienda'),
                  ),
                  for (final shop in _shops)
                    DropdownMenuItem<int>(
                      value: shop['id'],
                      child: Text(shop['name']),
                    )
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addGift,
                child: const Text('Agregar Regalo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
