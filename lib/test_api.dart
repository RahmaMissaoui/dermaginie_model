import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TestApiPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('API Test')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final url = Uri.parse('https://appmel-production.up.railway.app/register');
              final response = await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: '{"email":"test@test.com", "password":"test123"}',
              );
              print('Response status: ${response.statusCode}');
              print('Response body: ${response.body}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Status: ${response.statusCode}')),
              );
            },
            child: Text('Test API'),
          ),
        ),
      ),
    );
  }
}