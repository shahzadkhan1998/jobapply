import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/email_generator.dart';
import '../services/gemini_service.dart';

part 'email_event.dart';
part 'email_state.dart';

class EmailBloc extends Bloc<EmailEvent, EmailState> {
  final GeminiService _geminiService;

  EmailBloc(this._geminiService) : super(EmailInitial()) {
    on<GenerateEmail>(_onGenerateEmail);
  }

  Future<void> _onGenerateEmail(
    GenerateEmail event,
    Emitter<EmailState> emit,
  ) async {
    emit(EmailLoading());

    try {
      final prompt = '''
      Generate a professional job application email with the following details:
      
      Position: ${event.position}
      Company: ${event.company}
      Recipient: ${event.recipient}
      Subject: ${event.subject}
      Match Score: ${event.matchScore}%
      Skills: ${event.skills.join(', ')}
      
      The email should:
      1. Be professional and well-structured
      2. Highlight relevant skills and experience
      3. Show enthusiasm for the position
      4. Include a clear call to action
      5. Be concise but comprehensive
      
      Format the email with proper greeting, body, and closing.
      ''';

      final email = await _geminiService.generateContent(prompt) ?? '';
      emit(EmailSuccess(email));
    } catch (e) {
      emit(EmailError(e.toString()));
    }
  }
}