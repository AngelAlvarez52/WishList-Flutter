import 'package:flutter/material.dart';
import 'package:proyecto/CategoriesPage.dart';
import 'package:proyecto/CommentsPage.dart';
import 'package:proyecto/GiftsPage.dart';
import 'package:proyecto/RatingsPage.dart';
import 'package:proyecto/ShopsPage.dart';
import 'package:proyecto/UsersPage.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: <Widget>[
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CategoriesPage()),
                );
              },
              child: Container(
                height: 50,
                color: Colors.blue[500],
                child: const Center(child: Text('Categories')),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CommentsPage()),
                );
              },
              child: Container(
                height: 50,
                color: Colors.blue[500],
                child: const Center(child: Text('Comments')),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GiftsPage()),
                );
              },
              child: Container(
                height: 50,
                color: Colors.blue[500],
                child: const Center(child: Text('Gifts')),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RatingsPage()),
                );
              },
              child: Container(
                height: 50,
                color: Colors.blue[500],
                child: const Center(child: Text('Ratings')),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShopsPage()),
                );
              },
              child: Container(
                height: 50,
                color: Colors.blue[500],
                child: const Center(child: Text('Shops')),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UsersPage()),
                );
              },
              child: Container(
                height: 50,
                color: Colors.blue[500],
                child: const Center(child: Text('Users')),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
