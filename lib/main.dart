import 'package:flutter/material.dart';
import 'dart:convert'; // Para trabalhar com JSON
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String apiKey = 'key'; // Definindo a chave da API diretamente
  TextEditingController _cityController = TextEditingController();
  TextEditingController _countryController = TextEditingController();
  String _cityName = '';
  String _countryCode = '';
  String _temperature = '';
  String _description = '';
  String _humidity = '';
  String _windSpeed = '';
  String _weatherIcon = 'assets/images/clear.png'; // Imagem padrão

  // Map para associar tipos de clima com suas respectivas imagens
  final Map<String, String> weatherImages = {
    'Clear': 'assets/images/clear.png',
    'Clouds': 'assets/images/clouds.png',
    'Rain': 'assets/images/rain.png',
    'Snow': 'assets/images/snow.png',
    'Thunderstorm': 'assets/images/thunderstorm.png',
    'Drizzle': 'assets/images/drizzle.png',
    'Mist': 'assets/images/mist.png',
    'Error': 'assets/images/error.png',
  };

  // Função para fazer a solicitação à API
  Future<void> fetchData() async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$_cityName,$_countryCode&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      // Se a solicitação foi bem-sucedida, analise os dados JSON
      Map<String, dynamic> data = jsonDecode(response.body);
      String weatherMain = data['weather'][0]['main'];

      setState(() {
        _temperature = '${data['main']['temp']} °C';
        _description = data['weather'][0]['description'];
        _humidity = '${data['main']['humidity']} %';
        _windSpeed = '${data['wind']['speed']} m/s';
        _weatherIcon = weatherImages[weatherMain] ?? 'assets/images/clear.png'; // Atualiza a imagem baseada no clima
      });
    } else {
      // Se ocorreu algum erro, exiba o código de status
      setState(() {
        _temperature = '';
        _description = 'Request failed with status: ${response.statusCode}';
        _humidity = '';
        _windSpeed = '';
        _weatherIcon = 'assets/images/error.png'; // Imagem de erro
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.lightBlue[50],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Aplicativo de Clima'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 300,
                    child: TextField(
                      controller: _cityController,
                      onChanged: (value) {
                        setState(() {
                          _cityName = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Nome da Cidade',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: 300,
                    child: TextField(
                      controller: _countryController,
                      onChanged: (value) {
                        setState(() {
                          _countryCode = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Código do País',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Chama a função fetchData() quando o botão é pressionado
                      fetchData();
                    },
                    child: const Text('Pesquisar'),
                  ),
                  SizedBox(height: 20),
                  _description.isNotEmpty
                      ? Column(
                    children: [
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Image.asset(
                                _weatherIcon, // Exibe a imagem do clima
                                height: 100,
                                width: 100,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Cidade: $_cityName',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Temperatura: $_temperature',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Clima: $_description',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Umidade: $_humidity',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Velocidade do Vento: $_windSpeed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  )
                      : Container(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
