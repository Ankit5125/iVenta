import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_event_explorer_frontend/apis/storage/LocalStorage.dart';
import 'package:smart_event_explorer_frontend/models/UserModel.dart';
import 'package:smart_event_explorer_frontend/services/UserService.dart';

class Authentication {
  static String baseURL = "https://iventa-backend.onrender.com";

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      String url = "$baseURL/api/auth/login";

      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = decodedData['token'];

        if (token != null) {
          final msg = decodedData['msg'];
          await LocalStorage().set("token", token);

          User user = User.fromJson(decodedData);

          await UserService().saveUser(user);

          return {"login": true, "message": msg};
        }
      }

      // Error Handling
      if (decodedData['msg'] != null) {
        return {"login": false, "message": "${decodedData['msg']}"};
      }
      if (decodedData['errors'] != null && decodedData['errors'].isNotEmpty) {
        return {
          "login": false,
          "message": "${decodedData['errors'][0]['msg']}",
        };
      }

      return {"login": false, "message": "Something went Wrong"};
    } catch (error) {
      return {"login": false, "message": "Internal Error"};
    }
  }

  static Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      String url = "$baseURL/api/auth/register";

      var response = await http.post(
        Uri.parse(url),
        headers: {"content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = decodedData['token'];

        if (token != null) {
          await LocalStorage().set("token", token);

          User user = User.fromJson(decodedData);

          await UserService().saveUser(user);

          return {"signup": true, "message": "SignUp Succesfull"};
        }
      }

      // Error Handling
      if (decodedData['msg'] != null) {
        return {"signup": false, "message": "${decodedData['msg']}"};
      }
      if (decodedData['errors'] != null && decodedData['errors'].isNotEmpty) {
        return {
          "signup": false,
          "message": "${decodedData['errors'][0]['msg']}",
        };
      }

      return {"signup": false, "message": "Something went Wrong"};
    } catch (error) {
      return {"signup": false, "message": "Internal Error"};
    }
  }

  static Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      String url = "$baseURL/api/auth/forgot-password";

      var response = await http.post(
        Uri.parse(url),
        headers: {"content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final msg = decodedData['msg'];

        if (msg != null) {
          return {"otpsent": true, "message": msg};
        }
      }

      final msg = decodedData['errors'][0]['msg'];
      return {"otpsent": false, "message": msg};
    } catch (error) {
      return {"otpsent": false, "message": "Internal Error"};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String password,
  ) async {
    String url = "$baseURL/api/auth/reset-password/";

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {"content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp, "password": password}),
      );

      final decodedData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final msg = decodedData['msg'];

        if (msg != null) {
          return {"reset": true, "message": msg};
        }
      }

      return {"reset": false, "message": decodedData['msg']};
    } catch (error) {
      return {"reset": false, "message": "Internal Error"};
    }
  }
}
