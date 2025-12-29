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
  const ProfileAvatarUploadRequested(this.image);
  @override
  List<Object?> get props => [image];
}

class ProfileFollowUserRequested extends ProfileEvent {
  final String targetUserId;
  const ProfileFollowUserRequested(this.targetUserId);
  @override
  List<Object?> get props => [targetUserId];
}

class ProfileUnfollowUserRequested extends ProfileEvent {
  final String targetUserId;
  const ProfileUnfollowUserRequested(this.targetUserId);
  @override
  List<Object?> get props => [targetUserId];
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
  final bool isFollowing;
  const ProfileLoaded(this.profile, {this.isFollowing = false});
  @override
  List<Object?> get props => [profile, isFollowing];
  
  ProfileLoaded copyWith({UserProfile? profile, bool? isFollowing}) {
    return ProfileLoaded(
      profile ?? this.profile,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
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
    on<ProfileFollowUserRequested>(_onFollowRequested);
    on<ProfileUnfollowUserRequested>(_onUnfollowRequested);
  }

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await _profileRepository.getProfile(event.userId);
      if (profile != null) {
        final isFollowing = await _profileRepository.isFollowing(event.userId);
        emit(ProfileLoaded(profile, isFollowing: isFollowing));
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
      // Re-emit loaded with same follow status if possible, or just default
      // Since update is usually for self, isFollowing is likely false.
      emit(ProfileLoaded(event.profile, isFollowing: false)); 
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onAvatarUploadRequested(
    ProfileAvatarUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      emit(const ProfileError('Profil yüklenmemiş'));
      return;
    }
    
    final currentProfile = currentState.profile;
    final currentFollowStatus = currentState.isFollowing;
    
    emit(ProfileAvatarUploading());
    
    try {
      final avatarUrl = await _profileRepository.uploadAvatar(event.image);
      final updatedProfile = currentProfile.copyWith(avatarUrl: avatarUrl);
      await _profileRepository.updateProfile(updatedProfile);
      emit(ProfileLoaded(updatedProfile, isFollowing: currentFollowStatus));
    } catch (e) {
      emit(ProfileError(e.toString()));
      emit(ProfileLoaded(currentProfile, isFollowing: currentFollowStatus));
    }
  }

  Future<void> _onFollowRequested(
    ProfileFollowUserRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;
    
    try {
      await _profileRepository.followUser(event.targetUserId);
      
      // Optimistic update
      final updatedProfile = currentState.profile.copyWith(
        followersCount: currentState.profile.followersCount + 1,
      );
      emit(currentState.copyWith(profile: updatedProfile, isFollowing: true));
    } catch (e) {
      emit(ProfileError(e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onUnfollowRequested(
    ProfileUnfollowUserRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) return;
    
    try {
      await _profileRepository.unfollowUser(event.targetUserId);
      
      // Optimistic update
      final updatedProfile = currentState.profile.copyWith(
        followersCount: (currentState.profile.followersCount - 1).clamp(0, 999999),
      );
      emit(currentState.copyWith(profile: updatedProfile, isFollowing: false));
    } catch (e) {
      emit(ProfileError(e.toString()));
      emit(currentState);
    }
  }
}
