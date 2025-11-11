import '../services/plant_service.dart';
import '../models/plant_model.dart';

class PlantRepository {
  final PlantService plantService;

  PlantRepository({required this.plantService});

  Future<List<PlantModel>> getAllPlants(String accessToken) {
    return plantService.getAllPlants(accessToken);
  }

  Future<PlantModel> getPlantById(String id, String accessToken) {
    return plantService.getPlantById(id, accessToken);
  }

  Future<PlantModel> createPlant(CreatePlantModel plant, String accessToken) {
    return plantService.createPlant(plant, accessToken);
  }

  Future<PlantModel> updatePlant(String id, UpdatePlantModel plant, String accessToken) {
    return plantService.updatePlant(id, plant, accessToken);
  }

  Future<void> deletePlant(String id, String accessToken) {
    return plantService.deletePlant(id, accessToken);
  }
}