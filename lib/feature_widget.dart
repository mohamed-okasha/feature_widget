library feature_widget;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'env.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FeatureWidget extends StatefulWidget {
  final String feature;
  final Widget child;

  FeatureWidget({
    required this.feature,
    required this.child});

  @override
  _FeatureWidgetState createState() => _FeatureWidgetState();
}

class _FeatureWidgetState extends State<FeatureWidget> {
  bool _showChild = false;

  @override
  void initState() {
    super.initState();
    _loadPropertyState().then((state) async {
      bool isCacheExpired = await _isCacheExpired();
      if (state != null && ! await _isCacheExpired()) {
        setState(() {
          _showChild = state;
        });
      } else {
        loadEnv().then((_) => _checkProperty());
      }
    });
  }

  Future<void> _savePropertyState(bool state) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.feature, state);
    await prefs.setInt('${widget.feature}_timestamp', DateTime.now().millisecondsSinceEpoch);

  }

  Future<bool?> _loadPropertyState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(widget.feature);
  }

  Future<bool> _isCacheExpired() async {
    final ttl = Duration(seconds: 30).inMilliseconds;
    final now = DateTime.now().millisecondsSinceEpoch;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final lastFetchedTimestamp = prefs.getInt('${widget.feature}_timestamp') ?? 0;

    return now - lastFetchedTimestamp > ttl;
  }

  Future<void> _checkProperty() async {
    
    final apiUrl = dotenv.env['API_URL']!;
    final apiKey = dotenv.env['API_KEY']!;

    Uri parsedApiUrl = Uri.parse(apiUrl);
    Uri url = Uri(
      scheme: parsedApiUrl.scheme,
      host: parsedApiUrl.host,
      port: parsedApiUrl.port,
      path: '/api/features'
    );

    http.Response response = await http.get(url, headers: {
      'api-key': apiKey,
    });

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      setState(() {
        _showChild = responseData[widget.feature] ?? false;
      });
      await _savePropertyState(_showChild);
    } else {
      // Error handling
      throw Exception('Failed to load data from API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _showChild ? widget.child : Container();
  }
}
