import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String userId;
  const ProfileLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ProfileUpdateRequested extends ProfileEvent {
  final UserProfile profile;
  const ProfileUpdateRequested(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileAvatarUploadRequested extends ProfileEvent {
  final File image;
  final String userId;
  const ProfileAvatarUploadRequested(this.image, this.userId);
  @override
  List<Object?> get props => [image, userId];
}

// States
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  const ProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileUpdating extends ProfileState {}

class ProfileUpdated extends ProfileState {
  final UserProfile profile;
  const ProfileUpdated(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileAvatarUploading extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc(this._profileRepository) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfileAvatarUploadRequested>(_onAvatarUploadRequested);
  }

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await _profileRepository.getProfile(event.userId);
      if (profile != null) {
        emit(ProfileLoaded(profile));
      } else {
        emit(const ProfileError('Profil bulunamadı'));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating());
    try {
      await _profileRepository.updateProfile(event.profile);
      emit(ProfileUpdated(event.profile));
      emit(ProfileLoaded(event.profile)); // Back to loaded state
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onAvatarUploadRequested(
    ProfileAvatarUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileAvatarUploading());
    try {
      final avatarUrl = await _profileRepository.uploadAvatar(event.image, event.userId);
      
      // Get current profile and update avatar
      final currentProfile = await _profileRepository.getProfile(event.userId);
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(avatarUrl: avatarUrl);
        await _profileRepository.updateProfile(updatedProfile);
        emit(ProfileLoaded(updatedProfile));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
