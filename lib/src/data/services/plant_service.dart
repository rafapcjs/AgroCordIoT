import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plant_model.dart';
import '../../core/constants.dart';

class PlantService {
  Future<List<PlantModel>> getAllPlants(String accessToken) async {
    final url = Uri.parse('${Constants.baseUrl}/api/plants');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => PlantModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load plants');
    }
  }

  Future<PlantModel> getPlantById(String id, String accessToken) async {
    final url = Uri.parse('${Constants.baseUrl}/api/plants/$id');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200) {
      return PlantModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load plant');
    }
  }

  Future<int> getPlantCount(String accessToken) async {
    final url = Uri.parse('${Constants.baseUrl}/api/plants/count');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['count'];
    } else {
      throw Exception('Failed to get plant count');
    }
  }

  Future<PlantModel> createPlant(CreatePlantModel plant, String accessToken) async {
    final url = Uri.parse('${Constants.baseUrl}/api/plants');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode(plant.toJson()),
    );

    if (response.statusCode == 201) {
      return PlantModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create plant');
    }
  }

  Future<PlantModel> updatePlant(String id, UpdatePlantModel plant, String accessToken) async {
    if (id.isEmpty) {
      throw Exception('Plant ID cannot be empty');
    }
    
    final url = Uri.parse('${Constants.baseUrl}/api/plants/$id');
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode(plant.toJson()),
    );

    if (response.statusCode == 200) {
      return PlantModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update plant: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deletePlant(String id, String accessToken) async {
    if (id.isEmpty) {
      throw Exception('Plant ID cannot be empty');
    }
    
    final url = Uri.parse('${Constants.baseUrl}/api/plants/$id');
    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete plant: ${response.statusCode} - ${response.body}');
    }
  }
}