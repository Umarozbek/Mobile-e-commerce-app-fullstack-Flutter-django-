import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../data/models/location_model.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final List<LocationModel> locations;
  final LocationModel? selectedLocation;

  const LocationLoaded({
    required this.locations,
    this.selectedLocation,
  });

  @override
  List<Object?> get props => [locations, selectedLocation];

  LocationLoaded copyWith({
    List<LocationModel>? locations,
    LocationModel? selectedLocation,
  }) {
    return LocationLoaded(
      locations: locations ?? this.locations,
      selectedLocation: selectedLocation ?? this.selectedLocation,
    );
  }
}

class LocationError extends LocationState {
  final Failure message;

  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}
