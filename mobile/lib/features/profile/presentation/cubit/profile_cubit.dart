import 'package:bloc/bloc.dart';

import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/repository/profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit(this._profileRepository) : super(ProfileInitial());

  void getProfile() async {
    emit(ProfileLoading(type: 'profile'));
    final response = await _profileRepository.getProfile();
    response.fold(
      (l) => emit(ProfileError(failure: l, type: 'profile')),
      (r) => emit(ProfileSuccess(data: r, type: 'profile')),
    );
  }

  void updateProfile({required Map<String, dynamic> data}) async {
    emit(ProfileLoading(type: 'update'));
    final response = await _profileRepository.updateProfile(data: data);
    response.fold(
      (l) => emit(ProfileError(failure: l, type: 'update')),
      (r) {
        emit(ProfileSuccess(data: r, type: 'update'));
        getProfile(); // Refresh profile after update
      },
    );
  }

  void deleteProfile() async {
    emit(ProfileLoading(type: 'delete'));
    final response = await _profileRepository.deleteProfile();
    response.fold(
      (l) => emit(ProfileError(failure: l, type: 'delete')),
      (r) => emit(ProfileSuccess(data: r, type: 'delete')),
    );
  }

  void getLocations() async {
    emit(ProfileLoading(type: 'locations'));
    final response = await _profileRepository.getLocations();
    response.fold(
      (l) => emit(ProfileError(failure: l, type: 'locations')),
      (r) => emit(ProfileSuccess(data: r, type: 'locations')),
    );
  }

  void createLocation({required Map<String, dynamic> data}) async {
    emit(ProfileLoading(type: 'createLocation'));
    final response = await _profileRepository.createLocation(data: data);
    response.fold(
      (l) => emit(ProfileError(failure: l, type: 'createLocation')),
      (r) {
        emit(ProfileSuccess(data: r, type: 'createLocation'));
        getLocations(); // Refresh locations after creating
      },
    );
  }

  /// Logout paytida state tozalanadi
  void reset() => emit(ProfileInitial());
}

