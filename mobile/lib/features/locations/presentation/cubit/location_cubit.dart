
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/service/secure_storage.dart';
import '../../data/models/location_model.dart';
import '../../domain/repository/location_repository.dart';
import 'location_state.dart';

import 'dart:convert';

class LocationCubit extends Cubit<LocationState> {
  final LocationRepository _repository;

  LocationCubit(this._repository) : super(LocationInitial());

  final SecureStorage _storage = SecureStorage();
  static const String _locationsKey = 'saved_locations';
  static const String _selectedLocationKey = 'selected_location';

  /// Load all saved locations (Currently Local, need API for this too?)
  /// For now, I will keep local loading if no GET API is provided, 
  /// but `addLocation` will go to server.
  /// Ideally we should have a GET API.
  /// Load all saved locations from API
  Future<void> loadLocations() async {
    emit(LocationLoading());
    try {
      final result = await _repository.getLocations();
      
      result.fold(
        (failure) => emit(LocationError(failure)),
        (locations) async {
          // Check for locally saved selected location
          final selectedLocationJson = await _storage.read(key: _selectedLocationKey);
          LocationModel? selectedLocation;

          if (selectedLocationJson != null && selectedLocationJson.isNotEmpty) {
            try {
              final savedSelected = LocationModel.fromJson(jsonDecode(selectedLocationJson));
              // Verify if saved selected location still exists in new list
              selectedLocation = locations.firstWhere(
                (loc) => loc.id == savedSelected.id,
                orElse: () => locations.isNotEmpty ? locations.first : savedSelected,
              );
            } catch (_) {}
          } 
          
          if (selectedLocation == null && locations.isNotEmpty) {
            // Auto-select default or first location
            selectedLocation = locations.firstWhere(
              (loc) => loc.isDefault,
              orElse: () => locations.first,
            );
          }

          emit(LocationLoaded(
            locations: locations,
            selectedLocation: selectedLocation,
          ));
        },
      );
    } catch (e) {
      emit(LocationError(const Failure(error: 'Manzillarni yuklashda xatolik')));
    }
  }

  /// Add new location via API
  Future<void> addLocation(String address, bool active) async {
    emit(LocationLoading());
    try {
      final result = await _repository.createLocation(address: address, active: active);
      
      result.fold(
        (failure) => emit(LocationError(failure)),
        (newLocation) async {
             // Refresh list after addition to be safe or append
             // To ensure consistency, let's reload all locations
             await loadLocations();
        },
      );
    } catch (e) {
      emit(LocationError(const Failure(error: 'Manzil qo\'shishda xatolik')));
    }
  }

  /// Update existing location
  Future<void> updateLocation(int id, String address, bool active) async {
    emit(LocationLoading());
    try {
      final result = await _repository.updateLocation(
        id: id,
        address: address,
        active: active,
      );
      
      result.fold(
        (failure) => emit(LocationError(failure)),
        (updatedLocation) async {
          // Updates list after modification
          await loadLocations();
        },
      );
    } catch (e) {
      emit(LocationError(const Failure(error: 'Manzilni yangilashda xatolik')));
    }
  }

  /// Delete location via API
  Future<void> deleteLocation(int id) async {
    try {
      final result = await _repository.deleteLocation(id);
      
      result.fold(
        (failure) => emit(LocationError(failure)),
        (_) async {
          // Reload locations after deletion
          await loadLocations();
        },
      );
    } catch (e) {
      emit(LocationError(const Failure(error: 'Manzilni o\'chirishda xatolik')));
    }
  }

  /// Select location for checkout
  Future<void> selectLocation(LocationModel location) async {
    try {
      final currentState = state;
      if (currentState is! LocationLoaded) return;

      await _saveSelectedLocation(location);

      emit(currentState.copyWith(selectedLocation: location));
    } catch (e) {
      emit(LocationError(const Failure(error: 'Manzilni tanlashda xatolik')));
    }
  }



  /// Private: Save selected location to storage
  Future<void> _saveSelectedLocation(LocationModel location) async {
    final json = jsonEncode(location.toJson());
    await _storage.write(key: _selectedLocationKey, value: json);
  }

  /// Logout paytida state tozalanadi
  void reset() => emit(LocationInitial());
}
