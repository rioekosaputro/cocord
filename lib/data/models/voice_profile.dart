import 'package:flutter/material.dart';

enum VoiceProfileType {
  natural,
  maleWarm,
  femaleSmooth,
  deepBaritone,
  studioBroadcast,
}

class VoiceProfile {
  final VoiceProfileType type;
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final double pitchFactor; // 1.0 = Normal, 0.82 = Male, 1.25 = Female
  final String tag;

  const VoiceProfile({
    required this.type,
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.pitchFactor,
    required this.tag,
  });

  static const List<VoiceProfile> presets = [
    VoiceProfile(
      type: VoiceProfileType.natural,
      id: 'natural',
      name: 'Original Voice (Natural)',
      description: 'Clean untouched microphone sound with zero alteration.',
      icon: Icons.mic_rounded,
      pitchFactor: 1.0,
      tag: 'ORIGINAL',
    ),
    VoiceProfile(
      type: VoiceProfileType.maleWarm,
      id: 'male_warm',
      name: 'Natural Male (Warm & Deep)',
      description: 'Subtle acoustic pitch & formant shift for a warm, natural male tone.',
      icon: Icons.man_rounded,
      pitchFactor: 0.86,
      tag: 'MALE PITCH',
    ),
    VoiceProfile(
      type: VoiceProfileType.femaleSmooth,
      id: 'female_smooth',
      name: 'Natural Female (Bright & Clear)',
      description: 'Smooth harmonic pitch calibration for an authentic natural female voice.',
      icon: Icons.woman_rounded,
      pitchFactor: 1.22,
      tag: 'FEMALE PITCH',
    ),
    VoiceProfile(
      type: VoiceProfileType.deepBaritone,
      id: 'deep_baritone',
      name: 'Deep Baritone (Commander)',
      description: 'Rich low-end resonant vocal depth without robotic distortion.',
      icon: Icons.record_voice_over_rounded,
      pitchFactor: 0.76,
      tag: 'BARITONE',
    ),
    VoiceProfile(
      type: VoiceProfileType.studioBroadcast,
      id: 'studio_broadcast',
      name: 'Studio Broadcast / Radio',
      description: 'Crisp broadcast EQ presence with subtle studio warm compression.',
      icon: Icons.podcasts_rounded,
      pitchFactor: 1.04,
      tag: 'BROADCAST',
    ),
  ];
}
