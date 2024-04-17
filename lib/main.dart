import 'package:flutter/material.dart';
import 'dart:convert'; // Para trabalhar com JSON
import 'package:http/http.dart' as http;
import 'config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String apiKey = ''; // Sua chave de API

  // Função para fazer a solicitação à API
  Future<void> fetchData() async {
    final response = await http.get(
      Uri.parse('https://openweathermap.org/$word'),
      headers: {
        'Authorization': 'Bearer $apiKey', // Utiliza a chave de API do arquivo de configuração
      },
    );

    if (response.statusCode == 200) {
      // Se a solicitação foi bem-sucedida, analise os dados JSON
      Map<String, dynamic> data = jsonDecode(response.body);
      print(data); // Exibe os dados no console
    } else {
      // Se ocorreu algum erro, exiba o código de status
      print('Request failed with status: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Exemplo de Chamada de API'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // Chama a função fetchData() quando o botão é pressionado
              fetchData();
            },
            child: const Text('Chamar API'),
          ),
        ),
      ),
    );
  }
}
