// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

class GiftEditPage extends StatefulWidget {
  final String authToken;
  final int giftId;

  const GiftEditPage({Key? key, required this.authToken, required this.giftId})
      : super(key: key);

  @override
  GiftEditPageState createState() => GiftEditPageState();
}

class GiftEditPageState extends State<GiftEditPage> {
  late Future<Map<String, dynamic>> _giftDataFuture;
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedShopId;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _shops = [];
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchShops();
    _giftDataFuture = _fetchGiftData();
  }

  Future<Map<String, dynamic>> _fetchGiftData() async {
    final response = await http
        .get(Uri.parse('http://127.0.0.1:8000/api/Gifts/${widget.giftId}'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load gift data');
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

  Future<void> _updateGift() async {
    final url =
        Uri.parse('http://127.0.0.1:8000/api/Gifts/${widget.giftId}/update');

    final request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer ${widget.authToken}',
    });

    request.fields['id'] = widget.giftId.toString();
    request.fields['name'] = nameController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['url'] = urlController.text;
    request.fields['price'] = priceController.text;
    request.fields['category_id'] = _selectedCategoryId.toString();
    request.fields['shop_id'] = _selectedShopId.toString();

    // Adjuntar la imagen al formulario
    if (_imageUrl != null) {
      request.fields['image'] = _imageUrl!;
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      _logger.i('Gift added successfully');
      _logger.i(await response.stream.bytesToString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se actualizo el regalo'),
        ),
      );
      Navigator.pop(context,
          true); // Regresar a la página anterior y notificar que se agregó un regalo
    } else {
      _logger.e('No se pudo actualizar el reglo');
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
        title: const Text('Editar Regalo'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _giftDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final giftData = snapshot.data!;
            nameController.text = giftData['name'];
            descriptionController.text = giftData['description'];
            urlController.text = giftData['url'];
            priceController.text = giftData['price'].toString();
            _selectedCategoryId = giftData['category_id'];
            _selectedShopId = giftData['shop_id'];

            return SingleChildScrollView(
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
                    decoration: const InputDecoration(labelText: 'Descripción'),
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
                    onPressed: _updateGift,
                    child: const Text('Actualizar Regalo'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
