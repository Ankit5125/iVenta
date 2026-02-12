import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_event_explorer_frontend/apis/storage/LocalStorage.dart';
import 'package:smart_event_explorer_frontend/models/ApplicationStatusModel.dart';

class OrganizerApplicationRepository {
  static String baseURL = "https://iventa-backend.onrender.com";

  Future<ApplicationStatus> fetchLatestStatus() async {
    try {
      String? token = await LocalStorage().get("token");

      final response = await http.get(
        Uri.parse('$baseURL/api/users/application-status'),
        headers: {'x-auth-token': token ?? ""},
      );

      if (response.statusCode == 200) {
        return ApplicationStatus.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load status : ${response.body}');
      }
    } on Exception catch (e) {
      throw Exception('Internal Error ! : $e');
    }
  }

  Future<Map<String, dynamic>> sendApplication(
    String organizationName,
    String reason,
    String proposedEventName,
    String proposedEventDescription,
    String socialLinks,
  ) async {
    String? token = await LocalStorage().get("token");

    
    try {
      final response = await http.post(
        Uri.parse('$baseURL/api/users/apply-to-organize'),
        headers: {'x-auth-token': token ?? "", 
        'Content-Type': 'application/json'},
        body: jsonEncode({
          "organizationName": organizationName,
          "reason": reason,
          "proposedEventName": proposedEventName,
          "proposedEventDescription": proposedEventDescription,
          "socialLinks": socialLinks,
        }),
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"isError": false, "decodedData": decodedData};
      }
      if (decodedData['msg'] != null) {
        return {"isError": true, "decodedData": decodedData};
      }
      if (decodedData['errors'][0]['msg'] != null) {
        return {"isError": true, "data": decodedData};
      }
      throw Exception("Error : ${decodedData['msg']}");
    } on Exception catch (e) {
      throw Exception("Internal Error : $e}");
    }
  }
}
