import '../../../config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/vehicle.dart';

/// Vehicle repository - handles API calls for driver vehicles
class VehicleRepository {
  final DioClient _dioClient;

  VehicleRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// Get all vehicles for the current driver
  Future<List<Vehicle>> getVehicles() async {
    final response = await _dioClient.dio.get(ApiConfig.vehicles);
    final data = response.data as Map<String, dynamic>;
    // Backend returns { success: true, vehicles: [...] }
    final vehiclesData = data['vehicles'] as List<dynamic>? ?? [];
    return vehiclesData
        .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  /// Lookup vehicle by VRN (DVLA check without adding)
  Future<DvlaLookupResult> lookupVehicle(String vrn) async {
    final response = await _dioClient.dio.get(
      '${ApiConfig.vehicles}/lookup/$vrn',
    );
    final data = response.data as Map<String, dynamic>;
    // Backend returns { success: true, vehicle: {...} }
    final vehicleData = data['vehicle'] as Map<String, dynamic>;
    return DvlaLookupResult.fromJson(vehicleData);
  }

  /// Add a vehicle by VRN (performs DVLA lookup and adds)
  Future<Vehicle> addVehicle(String vrn) async {
    final response = await _dioClient.dio.post(
      ApiConfig.vehicles,
      data: {'vrn': vrn.toUpperCase().replaceAll(' ', '')},
    );
    final data = response.data as Map<String, dynamic>;
    // Backend returns { success: true, vehicle: {...} }
    final vehicleData = data['vehicle'] as Map<String, dynamic>;
    return Vehicle.fromJson(vehicleData);
  }

  /// Delete a vehicle
  Future<void> deleteVehicle(String vrn) async {
    await _dioClient.dio.delete('${ApiConfig.vehicles}/$vrn');
  }

  /// Refresh DVLA data for a vehicle
  Future<Vehicle> refreshVehicle(String vrn) async {
    final response = await _dioClient.dio.post(
      '${ApiConfig.vehicles}/$vrn/refresh',
    );
    final data = response.data as Map<String, dynamic>;
    final vehicleData = data['vehicle'] as Map<String, dynamic>;
    return Vehicle.fromJson(vehicleData);
  }
}
