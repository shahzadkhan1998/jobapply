import 'package:hive/hive.dart';
part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final List<String> skills;

  @HiveField(3)
  final List<WorkExperience> experience;

  @HiveField(4)
  final List<Education> education;

  @HiveField(5)
  final ContactInfo contactInfo;

  UserProfile(
    this.name,
    this.email, {
    required this.skills,
    required this.experience,
    required this.education,
    required this.contactInfo,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    List<String>? skills,
    List<WorkExperience>? experience,
    List<Education>? education,
    ContactInfo? contactInfo,
  }) {
    return UserProfile(
      name ?? this.name,
      email ?? this.email,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      contactInfo: contactInfo ?? this.contactInfo,
    );
  }
}

@HiveType(typeId: 1)
class WorkExperience {
  @HiveField(0)
  final String company;

  @HiveField(1)
  final String position;

  @HiveField(2)
  final DateTime startDate;

  @HiveField(3)
  final DateTime? endDate;

  @HiveField(4)
  final List<String> responsibilities;

  WorkExperience({
    required this.company,
    required this.position,
    required this.startDate,
    this.endDate,
    required this.responsibilities,
  });
}

@HiveType(typeId: 2)
class Education {
  @HiveField(0)
  final String institution;

  @HiveField(1)
  final String degree;

  @HiveField(2)
  final String field;

  @HiveField(3)
  final DateTime graduationDate;

  @HiveField(4)
  final double? gpa;

  @HiveField(5)
  final DateTime startDate;

  @HiveField(6)
  final DateTime? endDate;

  Education({
    required this.institution,
    required this.degree,
    required this.field,
    required this.graduationDate,
    this.gpa,
    required this.startDate,
    this.endDate,
  });
}

@HiveType(typeId: 3)
class ContactInfo {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String phone;

  @HiveField(3)
  final String? linkedIn;

  @HiveField(4)
  final String? portfolio;

  ContactInfo({
    required this.name,
    required this.email,
    required this.phone,
    this.linkedIn,
    this.portfolio,
  });
}
