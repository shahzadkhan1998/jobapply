import 'package:googleai_dart/googleai_dart.dart';

class GeminiService {
  final GoogleAIClient _client;

  GeminiService(String apiKey) : _client = GoogleAIClient(apiKey: apiKey);

  Future<String?> generateContent(String prompt) async {
    try {
      final res = await _client.generateContent(
        modelId: 'gemini-1.5-flash',
        request: GenerateContentRequest(
          contents: [
            Content(parts: [Part(text: prompt)]),
          ],
          generationConfig: GenerationConfig(temperature: 0.7),
        ),
      );
      return res.candidates?.firstOrNull?.content?.parts?.firstOrNull?.text;
    } catch (e) {
      throw Exception('Failed to generate content: $e');
    }
  }

  // Fix the return type (remove nested Future)
  Future<String?> generateProfessionalEmail({
    required String jobTitle,
    required String company,
    required String matchScore,
    required List<String> relevantSkills,
    required String experience,
    required String userName,
  }) async {
    final prompt = '''
    Generate a professional job application email with the following details:
    - Position: $jobTitle
    - Company: $company
    - Match Score: $matchScore%
    - Relevant Skills: ${relevantSkills.join(', ')}
    - Experience Summary: $experience
    - Applicant Name: $userName

    Requirements:
    - Keep it concise and professional
    - Highlight the match score and relevant skills
    - Include a brief mention of experience
    - End with a call to action
    - Use a formal business email format
    ''';

    return generateContent(prompt);
  }
}
