import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_event_explorer_frontend/apis/storage/LocalStorage.dart';
import 'package:smart_event_explorer_frontend/models/EventModel.dart';

class EventRepository {
  static final String baseURL = "https://iventa-backend.onrender.com";

  List<Event> _allEventsCache = [];
  List<Event> _trendingEventsCache = [];
  DateTime? _lastFetch;

  Future<List<Event>> getAllEvents() async {
    final token = await _getToken();

    // Cache valid for 10 minutes
    if (_allEventsCache.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 10) {
      return _allEventsCache;
    }

    final response = await http.get(
      Uri.parse("$baseURL/api/events/"),
      headers: {"x-auth-token": token},
    );

    _handleTokenError(response);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      _allEventsCache = data.map((e) => Event.fromJson(e)).toList();
      _lastFetch = DateTime.now();
      return _allEventsCache;
    }

    // throw Exception("FAILED_TO_FETCH_EVENTS");
    if (response.statusCode == 401) {
      return Future.error("AUTH_EXPIRED");
    }

    return Future.error("SOMETHING_WENT_WRONG");
  }

  Future<List<Event>> getTrendingEvents() async {
    final token = await _getToken();

    // Cache valid for 10 minutes
    if (_trendingEventsCache.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 10) {
      return _trendingEventsCache;
    }

    final response = await http.get(
      Uri.parse("$baseURL/api/events/trending"),
      headers: {"x-auth-token": token},
    );

    _handleTokenError(response);

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final List data = decoded["events"];
      _trendingEventsCache = data.map((e) => Event.fromJson(e)).toList();
      _lastFetch = DateTime.now();
      return _trendingEventsCache;
    }

    // throw Exception("AUTH_EXPIRED");
    if (response.statusCode == 401) {
      return Future.error("AUTH_EXPIRED");
    }

    return Future.error("SOMETHING_WENT_WRONG");
  }

  Future<List<Event>> refreshEvents() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseURL/api/events/"),
      headers: {"x-auth-token": token},
    );

    _handleTokenError(response);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      _allEventsCache = data.map((e) => Event.fromJson(e)).toList();
      _lastFetch = DateTime.now();
      return _allEventsCache;
    }

    throw Exception("FAILED_TO_REFRESH");
  }

  Future<Event> getMoreEventInfo(String eventID) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseURL/api/events/$eventID"),
      headers: {"x-auth-token": token},
    );

    _handleTokenError(response);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Event.fromJson(data);
    }

    throw Exception("FAILED_TO_FETCH_EVENT_DETAILS");
  }

  // sort by name, newest
  Future<List<Event>> searchEvent(
    String keyword, {
    bool isFree = true,
    String sortBy = "newest",
  }) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseURL/api/events/search?keyword=$keyword"),
      headers: {"x-auth-token": token},
    );

    _handleTokenError(response);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final List eventData = data['events'];
      List<Event> searchedEvents = eventData
          .map((e) => Event.fromJson(e))
          .toList();


      return searchedEvents;
    }

    throw Exception("FAILED_TO_SEARCH_EVENTS");
  }

  void _handleTokenError(http.Response response) async {
    if (response.statusCode == 401 ||
        response.body.contains("invalid") ||
        response.body.contains("expired")) {
      await LocalStorage().delete("token");
      throw Exception("AUTH_EXPIRED");
    }
    return;
  }

  Future<String> _getToken() async {
    return await LocalStorage().get("token") ?? "";
  }
}
