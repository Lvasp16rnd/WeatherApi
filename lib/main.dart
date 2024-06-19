import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ClimaApp());
}

class ClimaApp extends StatelessWidget {
  const ClimaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.lightBlue[50],
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String cityName = '';
  String countryCode = '';
  bool showSearchFields = false;
  final String apiKey = '597afd26db8fc12ebfa95e9c03f8c9b9';
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

  @override
  void initState() {
    super.initState();
    loadFixedLocation();
  }

  Future<void> loadFixedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cityName = prefs.getString('fixedCityName') ?? '';
      countryCode = prefs.getString('fixedCountryCode') ?? '';
    });
  }

  Future<void> saveFixedLocation(String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fixedCityName', city);
    await prefs.setString('fixedCountryCode', country);
    setState(() {
      cityName = city;
      countryCode = country;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clima'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                showSearchFields = !showSearchFields;
              });
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showSearchFields) buildSearchFields(context),
                SizedBox(height: 20),
                Text(
                  'Localização Fixa:',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Cidade: $cityName',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'País: $countryCode',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CurrentWeatherScreen(
                          cityName: cityName,
                          countryCode: countryCode,
                          apiKey: apiKey,
                          weatherImages: weatherImages,
                          saveFixedLocation: saveFixedLocation,
                        ),
                      ),
                    );
                  },
                  child: const Text('Clima Atual'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeatherForecastScreen(
                          cityName: cityName,
                          countryCode: countryCode,
                          apiKey: apiKey,
                          weatherImages: weatherImages,
                        ),
                      ),
                    );
                  },
                  child: const Text('Previsão do Tempo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSearchFields(BuildContext context) {
    TextEditingController cityController = TextEditingController();
    TextEditingController countryController = TextEditingController();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              child: TextField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: 'Cidade',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Container(
              width: 100,
              child: TextField(
                controller: countryController,
                decoration: InputDecoration(
                  labelText: 'País',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showSearchFields = false;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CurrentWeatherScreen(
                      cityName: cityController.text,
                      countryCode: countryController.text,
                      apiKey: apiKey,
                      weatherImages: weatherImages,
                      saveFixedLocation: saveFixedLocation,
                    ),
                  ),
                );
              },
              child: const Text('Pesquisar'),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }
}

class CurrentWeatherScreen extends StatefulWidget {
  final String cityName;
  final String countryCode;
  final String apiKey;
  final Map<String, String> weatherImages;
  final Future<void> Function(String city, String country) saveFixedLocation;

  CurrentWeatherScreen({
    required this.cityName,
    required this.countryCode,
    required this.apiKey,
    required this.weatherImages,
    required this.saveFixedLocation,
  });

  @override
  _CurrentWeatherScreenState createState() => _CurrentWeatherScreenState();
}

class _CurrentWeatherScreenState extends State<CurrentWeatherScreen> {
  String _temperature = '';
  String _description = '';
  String _humidity = '';
  String _windSpeed = '';
  String _weatherIcon = 'assets/images/clear.png';
  String _airQualityMessage = '';
  Color _airQualityColor = Colors.green; // default color

  @override
  void initState() {
    super.initState();
    fetchCurrentWeather();
    fetchAirQuality();
  }

  Future<void> fetchCurrentWeather() async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=${widget.cityName},${widget.countryCode}&appid=${widget.apiKey}&units=metric'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      String weatherMain = data['weather'][0]['main'];

      setState(() {
        _temperature = '${data['main']['temp']} °C';
        _description = data['weather'][0]['description'];
        _humidity = '${data['main']['humidity']} %';
        _windSpeed = '${data['wind']['speed']} m/s';
        _weatherIcon = widget.weatherImages[weatherMain] ?? 'assets/images/clear.png';
      });
    } else {
      setState(() {
        _temperature = '';
        _description = 'Request failed with status: ${response.statusCode}';
        _humidity = '';
        _windSpeed = '';
        _weatherIcon = 'assets/images/error.png';
      });
    }
  }

  Future<void> fetchAirQuality() async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/air_pollution?lat=${widget.cityName}&lon=${widget.countryCode}&appid=${widget.apiKey}'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      int aqi = data['list'][0]['main']['aqi'];
      Map<String, dynamic> components = data['list'][0]['components'];

      setState(() {
        _airQualityMessage = getAirQualityMessage(aqi);
        _airQualityColor = getAirQualityColor(aqi);
      });
    } else {
      setState(() {
        _airQualityMessage = 'Failed to fetch air quality data';
        _airQualityColor = Colors.grey;
      });
    }
  }

  String getAirQualityMessage(int aqi) {
    switch (aqi) {
      case 1:
        return 'Qualidade do ar boa. Sem riscos à saúde.';
      case 2:
        return 'Qualidade do ar aceitável. Pessoas sensíveis devem evitar atividades ao ar livre prolongadas.';
      case 3:
        return 'Qualidade do ar moderada. Pessoas sensíveis podem ter efeitos à saúde.';
      case 4:
        return 'Qualidade do ar ruim. Alerta de saúde: todos podem experimentar efeitos à saúde; recomenda-se redução de atividades ao ar livre.';
      case 5:
        return 'Qualidade do ar muito ruim. Todos devem evitar atividades ao ar livre.';
      default:
        return 'Sem dados disponíveis.';
    }
  }

  Color getAirQualityColor(int aqi) {
    switch (aqi) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFixedLocation = widget.cityName == 'yourFixedCityName' && widget.countryCode == 'yourFixedCountryCode';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clima Atual'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                _weatherIcon,
                height: 100,
                width: 100,
              ),
              SizedBox(height: 20),
              Text(
                'Cidade: ${widget.cityName}',
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
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(10),
                color: _airQualityColor.withOpacity(0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qualidade do Ar: $_airQualityMessage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _airQualityColor,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Recomendações:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _airQualityColor,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      getAirQualityRecommendations(),
                      style: TextStyle(
                        fontSize: 14,
                        color: _airQualityColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Mais Informações'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Cidade: ${widget.cityName}'),
                          Text('País: ${widget.countryCode}'),
                          Text('Temperatura: $_temperature'),
                          Text('Clima: $_description'),
                          Text('Umidade: $_humidity'),
                          Text('Velocidade do Vento: $_windSpeed'),
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.all(10),
                            color: _airQualityColor.withOpacity(0.2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Qualidade do Ar: $_airQualityMessage',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _airQualityColor,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Recomendações:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _airQualityColor,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  getAirQualityRecommendations(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _airQualityColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Mais Informações'),
              ),
              if (!isFixedLocation)
                ElevatedButton(
                  onPressed: () {
                    widget.saveFixedLocation(widget.cityName, widget.countryCode);
                  },
                  child: const Text('Fixar Localização'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String getAirQualityRecommendations() {
    // Exemplo de recomendações com base no índice de qualidade do ar (AQI)
    // Adaptar conforme orientações oficiais de saúde pública para qualidade do ar
    if (_airQualityMessage.contains('boa')) {
      return 'Não é necessário tomar precauções adicionais.';
    } else if (_airQualityMessage.contains('aceitável')) {
      return 'Pessoas sensíveis devem considerar limitar o tempo ao ar livre.';
    } else if (_airQualityMessage.contains('moderada')) {
      return 'Pessoas sensíveis podem experimentar efeitos à saúde; considere limitar o tempo ao ar livre.';
    } else if (_airQualityMessage.contains('ruim')) {
      return 'Todos podem experimentar efeitos à saúde; evite atividades ao ar livre e considere o uso de máscaras de proteção.';
    } else if (_airQualityMessage.contains('muito ruim')) {
      return 'Evite atividades ao ar livre; use máscaras de proteção se necessário e considere fechar portas e janelas.';
    } else {
      return 'Sem recomendações disponíveis.';
    }
  }
}

class WeatherForecastScreen extends StatefulWidget {
  final String cityName;
  final String countryCode;
  final String apiKey;
  final Map<String, String> weatherImages;

  WeatherForecastScreen({
    required this.cityName,
    required this.countryCode,
    required this.apiKey,
    required this.weatherImages,
  });

  @override
  _WeatherForecastScreenState createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> {
  List<Map<String, dynamic>> _forecast = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchWeatherForecast() async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/forecast?q=${widget.cityName},${widget.countryCode}&appid=${widget.apiKey}&units=metric'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      List<Map<String, dynamic>> forecast = [];

      for (var entry in data['list']) {
        forecast.add({
          'date': entry['dt_txt'],
          'temperature': entry['main']['temp'],
          'description': entry['weather'][0]['description'],
          'icon': widget.weatherImages[entry['weather'][0]['main']] ?? 'assets/images/clear.png',
        });
      }

      setState(() {
        _forecast = forecast;
      });
    } else {
      setState(() {
        _forecast = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsão do Tempo'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    fetchWeatherForecast();
                  },
                  child: const Text('Obter Previsão'),
                ),
                SizedBox(height: 20),
                _forecast.isNotEmpty ? buildForecastList() : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildForecastList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _forecast.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            leading: Image.asset(
              _forecast[index]['icon'],
              width: 50,
              height: 50,
            ),
            title: Text(
              'Data: ${_forecast[index]['date']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Temperatura: ${_forecast[index]['temperature']} °C'),
                Text('Clima: ${_forecast[index]['description']}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
