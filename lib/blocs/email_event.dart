part of 'email_bloc.dart';

abstract class EmailEvent {}

class GenerateEmail extends EmailEvent {
  final String position;
  final String company;
  final List<String> skills;
  final int matchScore;
  final String recipient;
  final String subject;

  GenerateEmail({
    required this.position,
    required this.company,
    required this.skills,
    required this.matchScore,
    required this.recipient,
    required this.subject,
  });
}