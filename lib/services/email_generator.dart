
import '../models/user_profile.dart';
import 'gemini_service.dart';

class EmailGenerator {
  final GeminiService _geminiService;
  
  // Move static templates inside the class
  static const List<String> _greetingTemplates = [
    'Dear {hiringManager},',
    'Hello {hiringManager},',
    'Greetings {hiringManager},'
  ];

  static const List<String> _openingTemplates = [
    'I am writing to express my strong interest in the {position} position at {company}.',
    'I am excited to apply for the {position} role at {company}.',
    'I was thrilled to learn about the {position} opportunity at {company}.',
    'Your {position} position at {company} immediately caught my attention.',
    'I am reaching out regarding the {position} role currently available at {company}.',
    'The {position} opportunity at {company} aligns perfectly with my career goals.'
  ];

  static const List<String> _matchScoreTemplates = [
    'With my background closely aligning with your requirements ({matchScore}% match),',
    'Based on my relevant experience ({matchScore}% match),',
    'Given my matching qualifications ({matchScore}% match),',
    'As my profile demonstrates a strong alignment ({matchScore}% match) with your needs,',
    'With a {matchScore}% match to your requirements,',
    'Having skills and experience that align {matchScore}% with your needs,'
  ];

  static const List<String> _skillsTemplates = [
    'I bring expertise in {skills}.',
    'My proficiency includes {skills}.',
    'I have developed strong capabilities in {skills}.',
    'I offer extensive experience with {skills}.',
    'My technical toolkit includes proficiency in {skills}.',
    'I have mastered and successfully applied {skills} in real-world projects.'
  ];

  static const List<String> _closingTemplates = [
    'I look forward to discussing how my skills and experience can contribute to {company}\'s success.',
    'I would welcome the opportunity to further discuss how I can contribute to your team.',
    'I am eager to explore how my background aligns with your needs in more detail.',
    'I would appreciate the chance to discuss how I can add value to {company}\'s team.',
    'I am excited about the possibility of bringing my expertise to {company}.',
    'I would value the opportunity to demonstrate how I can contribute to {company}\'s continued growth.'
  ];

  EmailGenerator(this._geminiService);

  // Simple email generation method
  Future<String> generateEmail({
    required String position,
    required String company,
    required List<String> skills,
    required int matchScore,
  }) async {
    try {
      final prompt = '''
        Generate a professional job application email for:
        Position: $position
        Company: $company
        My relevant skills: ${skills.join(', ')}
        Match score with job requirements: $matchScore%
        
        Make it concise, professional, and highlight my relevant skills.
      ''';

      final response = await _geminiService.generateContent(prompt);
      return response ?? 'Failed to generate email content'; // Handle null case
    } catch (e) {
      throw Exception('Failed to generate email: $e');
    }
  }

  // Advanced email generation method
  Future<String> generateDetailedEmail({
    required UserProfile profile,
    required Map<String, dynamic> jobDescription,
    required double matchScore,
    required String hiringManager,
  }) async {
    final company = jobDescription['company'] as String;
    final position = jobDescription['title'] as String;
    final matchScorePercentage = (matchScore * 100).round();
    final experienceParagraph = _generateExperienceParagraph(profile, company);
    final relevantSkills = _getRelevantSkills(
      profile.skills,
      jobDescription['required_skills'] as List<String>? ?? [],
    );
    
    try {
      final emailBody = await _geminiService.generateContent(
        _generateDetailedPrompt(
          position: position,
          company: company,
          matchScore: matchScorePercentage,
          skills: relevantSkills,
          experience: experienceParagraph,
          hiringManager: hiringManager,
        ),
      );
      
      final validatedEmail = _validateGrammar(emailBody ?? ''); // Handle null case
      return validatedEmail + '''

${profile.contactInfo.name}
${profile.contactInfo.email}
${profile.contactInfo.phone}
'''.trim();
    } catch (e) {
      throw Exception('Failed to generate email: $e');
    }
  }

  String _generateDetailedPrompt({
    required String position,
    required String company,
    required int matchScore,
    required List<String> skills,
    required String experience,
    required String hiringManager,
  }) {
    final greeting = _getRandomTemplate(_greetingTemplates).replaceAll('{hiringManager}', hiringManager);
    final opening = _getRandomTemplate(_openingTemplates)
        .replaceAll('{position}', position)
        .replaceAll('{company}', company);
    final matchScoreText = _getRandomTemplate(_matchScoreTemplates).replaceAll('{matchScore}', matchScore.toString());
    final skillsText = _getRandomTemplate(_skillsTemplates).replaceAll('{skills}', skills.join(', '));
    final closing = _getRandomTemplate(_closingTemplates).replaceAll('{company}', company);

    return '''
$greeting

$opening
$matchScoreText
$skillsText
$experience

$closing

Best regards,
''';
  }

  String _getRandomTemplate(List<String> templates) {
    templates.shuffle();
    return templates.first;
  }

  List<String> _getRelevantSkills(List<String> userSkills, List<String> requiredSkills) {
    if (requiredSkills.isEmpty) return userSkills.take(5).toList();

    final relevantSkills = userSkills.where((skill) {
      return requiredSkills.any((reqSkill) =>
          skill.toLowerCase().contains(reqSkill.toLowerCase()) ||
          reqSkill.toLowerCase().contains(skill.toLowerCase()));
    }).toList();

    relevantSkills.shuffle();
    return relevantSkills.take(5).toList();
  }

  String _generateExperienceParagraph(UserProfile profile, String company) {
    if (profile.experience.isEmpty) return '';

    final mostRecentExp = profile.experience.first;
    final previousExp = profile.experience.length > 1 ? profile.experience[1] : null;
    
    var paragraph = '''In my current role at ${mostRecentExp.company}, 
I have successfully ${mostRecentExp.responsibilities.take(2).join(" and ")}, 
demonstrating my ability to deliver impactful results.'''.trim();
    
    if (previousExp != null) {
      paragraph += ''' Prior to this, at ${previousExp.company}, I expanded my expertise through 
${previousExp.responsibilities.take(1).join(", ")}, 
further developing my professional capabilities.'''.trim();
    }

    paragraph += ''' This comprehensive background makes me uniquely qualified for the ${company} team, where I can leverage my proven track record to drive success.'''.trim();
    return paragraph;
  }

  String _validateGrammar(String text) {
    var processedText = text.trim();
    processedText = processedText.replaceAll(RegExp(r'([.!?])([A-Z])'), r'$1 $2');
    processedText = processedText.replaceAll(RegExp(r'\s+'), ' ');
    
    final sentences = processedText.split(RegExp(r'(?<=[.!?])\s+'));
    final correctedSentences = sentences.map((sentence) {
      var trimmedSentence = sentence.trim();
      
      if (trimmedSentence.isNotEmpty) {
        trimmedSentence = trimmedSentence[0].toUpperCase() + trimmedSentence.substring(1);
      }
      
      if (!trimmedSentence.endsWith('.') && !trimmedSentence.endsWith('!') && !trimmedSentence.endsWith('?')) {
        trimmedSentence = '$trimmedSentence.';
      }
      
      return trimmedSentence;
    }).toList();

    return correctedSentences.join(' ');
  }
}
