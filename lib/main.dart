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
  int? _aqi;
  Color _airQualityColor = Colors.white;
  String _airQualityMessage = '';

  List<HourlyForecast> _hourlyForecasts = [];

  @override
  void initState() {
    super.initState();
    fetchCurrentWeather();
    fetchHourlyForecast();
    fetchAirQuality();
  }

  Future<void> fetchCurrentWeather() async {
    final response = await http.get(
      Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=${widget.cityName},${widget.countryCode}&appid=${widget.apiKey}&units=metric'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      String weatherMain = data['weather'][0]['main'];

      setState(() {
        _temperature = '${data['main']['temp']} °C';
        _description = data['weather'][0]['description'];
        _humidity = '${data['main']['humidity']} %';
        _windSpeed = '${data['wind']['speed']} m/s';
        _weatherIcon =
            widget.weatherImages[weatherMain] ?? 'assets/images/clear.png';
      });
    } else {
      setState(() {
        _temperature = '';
        _description =
        'Request failed with status: ${response.statusCode}';
        _humidity = '';
        _windSpeed = '';
        _weatherIcon = 'assets/images/error.png';
      });
    }
  }

  Future<void> fetchHourlyForecast() async {
    final response = await http.get(
      Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=${widget.cityName},${widget.countryCode}&appid=${widget.apiKey}&units=metric'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      List<dynamic> hourlyData = data['list'];

      setState(() {
        _hourlyForecasts = hourlyData.map((e) => HourlyForecast.fromJson(e)).toList();
      });
    } else {
      print('Failed to load hourly forecast');
    }
  }

  Future<void> fetchAirQuality() async {
    final response = await http.get(
      Uri.parse(
          'https://api.openweathermap.org/data/2.5/air_pollution?lat=35&lon=139&appid=${widget.apiKey}'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      int aqi = data['list'][0]['main']['aqi'];
      setState(() {
        _aqi = aqi;
        _airQualityColor = getAirQualityColor(_aqi!);
        _airQualityMessage = getAirQualityMessage(_aqi!);
      });
    } else {
      setState(() {
        _airQualityMessage = 'Failed to fetch air data.';
      });
    }
  }

  Color getAirQualityColor(int aqi) {
    if (aqi >= 0 && aqi <= 50) {
      return Colors.green;
    } else if (aqi >= 51 && aqi <= 100) {
      return Colors.yellow;
    } else if (aqi >= 101 && aqi <= 150) {
      return Colors.orange;
    } else if (aqi >= 151 && aqi <= 200) {
      return Colors.red;
    } else if (aqi >= 201 && aqi <= 300) {
      return Colors.purple;
    } else {
      return Colors.black;
    }
  }

  String getAirQualityMessage(int aqi) {
    if (aqi >= 0 && aqi <= 50) {
      return 'Qualidade do ar boa. Aproveite!';
    } else if (aqi >= 51 && aqi <= 100) {
      return 'Qualidade do ar moderada. Pessoas sensíveis podem sentir impactos.';
    } else if (aqi >= 101 && aqi <= 150) {
      return 'Qualidade do ar não saudável para grupos sensíveis.';
    } else if (aqi >= 151 && aqi <= 200) {
      return 'Qualidade do ar não saudável. Todos podem começar a sentir efeitos na saúde.';
    } else if (aqi >= 201 && aqi <= 300) {
      return 'Qualidade do ar muito ruim. Alerta de saúde: todos podem experimentar efeitos mais graves na saúde.';
    } else {
      return 'Qualidade do ar perigosa. A saúde pode ser impactada severamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cityName}, ${widget.countryCode}'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AirQualityScreen(
                    cityName: widget.cityName,
                    countryCode: widget.countryCode,
                    apiKey: widget.apiKey,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.push_pin),
            onPressed: () {
              widget.saveFixedLocation(widget.cityName, widget.countryCode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Localização fixa atualizada para: ${widget.cityName}, ${widget.countryCode}'),
                  duration: Duration(seconds: 3),
                ),
              );
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
                Image.asset(
                  _weatherIcon,
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 20),
                Text(
                  '$_temperature',
                  style: TextStyle(fontSize: 24),
                ),
                Text(
                  '$_description',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Umidade',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text('$_humidity'),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Vel. do Vento',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text('$_windSpeed'),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _airQualityColor,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Qualidade do Ar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '$_airQualityMessage',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Previsão do Tempo para as próximas horas:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                if (_hourlyForecasts.isNotEmpty)
                  Column(
                    children: _hourlyForecasts
                        .map((forecast) => HourlyForecastWidget(forecast))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AirQualityScreen extends StatelessWidget {
  final String cityName;
  final String countryCode;
  final String apiKey;

  AirQualityScreen({
    required this.cityName,
    required this.countryCode,
    required this.apiKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Qualidade do Ar - $cityName, $countryCode'),
      ),
      body: Center(
        child: FutureBuilder(
          future: fetchAirQuality(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else {
              if (snapshot.hasError) {
                return Text('Erro ao carregar dados: ${snapshot.error}');
              } else {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud,
                        size: 100,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Qualidade do Ar',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        snapshot.data.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<String> fetchAirQuality() async {
    final response = await http.get(
      Uri.parse(
          'https://api.openweathermap.org/data/2.5/air_pollution?lat=35&lon=139&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      int aqi = data['list'][0]['main']['aqi'];
      return getAirQualityMessage(aqi);
    } else {
      return 'Falha ao obter dados de qualidade do ar';
    }
  }

  String getAirQualityMessage(int aqi) {
    if (aqi >= 0 && aqi <= 50) {
      return 'Qualidade do ar boa. Aproveite!';
    } else if (aqi >= 51 && aqi <= 100) {
      return 'Qualidade do ar moderada. Pessoas sensíveis podem sentir impactos.';
    } else if (aqi >= 101 && aqi <= 150) {
      return 'Qualidade do ar não saudável para grupos sensíveis.';
    } else if (aqi >= 151 && aqi <= 200) {
      return 'Qualidade do ar não saudável. Todos podem começar a sentir efeitos na saúde.';
    } else if (aqi >= 201 && aqi <= 300) {
      return 'Qualidade do ar muito ruim. Alerta de saúde: todos podem experimentar efeitos mais graves na saúde.';
    } else {
      return 'Qualidade do ar perigosa. A saúde pode ser impactada severamente.';
    }
  }
}

class WeatherForecastScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Previsão do Tempo - $cityName, $countryCode'),
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class HourlyForecast {
  final String time;
  final String temperature;
  final String weatherIcon;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherIcon,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    String time = json['dt_txt'];
    String temperature = json['main']['temp'].toString() + ' °C';
    String weatherMain = json['weather'][0]['main'];
    String weatherIcon = getWeatherIcon(weatherMain);

    return HourlyForecast(
      time: time,
      temperature: temperature,
      weatherIcon: weatherIcon,
    );
  }

  static String getWeatherIcon(String weatherMain) {
    switch (weatherMain) {
      case 'Clear':
        return 'assets/images/clear.png';
      case 'Clouds':
        return 'assets/images/clouds.png';
      case 'Rain':
        return 'assets/images/rain.png';
      case 'Snow':
        return 'assets/images/snow.png';
      case 'Thunderstorm':
        return 'assets/images/thunderstorm.png';
      case 'Drizzle':
        return 'assets/images/drizzle.png';
      case 'Mist':
        return 'assets/images/mist.png';
      default:
        return 'assets/images/error.png';
    }
  }
}

class HourlyForecastWidget extends StatelessWidget {
  final HourlyForecast forecast;

  HourlyForecastWidget(this.forecast);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            forecast.time.substring(11, 16),
            style: TextStyle(fontSize: 16),
          ),
          Image.asset(
            forecast.weatherIcon,
            width: 40,
            height: 40,
          ),
          Text(
            forecast.temperature,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
