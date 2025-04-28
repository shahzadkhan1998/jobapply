import 'dart:convert';
import 'package:googleai_dart/googleai_dart.dart';
import 'gemini_service.dart'; // Import GeminiService
import '../models/user_profile.dart';
import '../models/user_profile.dart' show WorkExperience, Education;

class JobMatcher {
  final GeminiService _geminiService; // Inject GeminiService
  // Constructor to receive GeminiService
  JobMatcher(this._geminiService);

  // Improved skill matching with fuzzy matching and variations
  List<String> _findMatchedSkills(List<String> userSkills, List<String> requiredSkills) {
    print('User Skills: $userSkills');
    print('Required Skills: $requiredSkills');
    
    final userSkillsLower = userSkills.map((s) => s.toLowerCase()).toSet();
    final matchedSkills = <String>[];
    final unmatchedSkills = <String>[];

    for (final reqSkill in requiredSkills) {
      final reqSkillLower = reqSkill.toLowerCase();
      bool isMatched = false;
      
      // Direct match
      if (userSkillsLower.contains(reqSkillLower)) {
        matchedSkills.add(reqSkill);
        print('Direct match found for: $reqSkill');
        isMatched = true;
        continue;
      }

      // Check for variations and partial matches
      for (final userSkill in userSkills) {
        final userSkillLower = userSkill.toLowerCase();
        
        // Check if one skill contains the other
        if (userSkillLower.contains(reqSkillLower) || reqSkillLower.contains(userSkillLower)) {
          matchedSkills.add(reqSkill);
          print('Partial match found: $userSkill matches $reqSkill');
          isMatched = true;
          break;
        }

        // Check for common variations
        if (_areSkillsEquivalent(userSkillLower, reqSkillLower)) {
          matchedSkills.add(reqSkill);
          print('Variation match found: $userSkill is equivalent to $reqSkill');
          isMatched = true;
          break;
        }
      }

      if (!isMatched) {
        unmatchedSkills.add(reqSkill);
        print('No match found for: $reqSkill');
      }
    }

    print('Matched Skills: $matchedSkills');
    print('Unmatched Skills: $unmatchedSkills');
    return matchedSkills;
  }

  bool _areSkillsEquivalent(String skill1, String skill2) {
    // Common skill variations and synonyms
    final skillVariations = {
      'javascript': ['js', 'ecmascript', 'es6', 'es7', 'es8', 'es9', 'es10'],
      'typescript': ['ts', 'typescript.js'],
      'react': ['reactjs', 'react.js', 'react native', 'reactjs', 'reactjs.js'],
      'node': ['nodejs', 'node.js', 'express', 'express.js'],
      'python': ['py', 'python3', 'python 3'],
      'java': ['j2ee', 'j2se', 'spring', 'spring boot', 'hibernate'],
      'c#': ['csharp', 'dotnet', '.net', 'asp.net', 'core.net'],
      '.net': ['dotnet', 'asp.net', 'core.net', 'c#', 'csharp'],
      'sql': ['mysql', 'postgresql', 'postgres', 'mssql', 'sql server', 'oracle', 'sqlite'],
      'nosql': ['mongodb', 'couchdb', 'cassandra', 'redis'],
      'aws': ['amazon web services', 'amazon aws', 'aws cloud'],
      'azure': ['microsoft azure', 'azure cloud'],
      'gcp': ['google cloud platform', 'google cloud', 'gcp cloud'],
      'devops': ['ci/cd', 'continuous integration', 'continuous deployment', 'jenkins', 'gitlab ci', 'github actions'],
      'agile': ['scrum', 'kanban', 'sprint', 'sprint planning'],
      'ui': ['user interface', 'frontend', 'front-end', 'front end', 'ui/ux'],
      'ux': ['user experience', 'ui/ux', 'user interface'],
      'api': ['rest api', 'graphql', 'restful', 'restful api', 'web api'],
      'mobile': ['ios', 'android', 'react native', 'flutter', 'mobile app', 'mobile development'],
      'flutter': ['flutter app', 'flutter development', 'flutter mobile', 'flutter web'],
      'dart': ['dart programming', 'dart language'],
      'firebase': ['firebase auth', 'firebase database', 'firebase storage', 'firebase hosting'],
    };

    // Check if skills are in the same variation group
    for (final variations in skillVariations.values) {
      if (variations.contains(skill1) && variations.contains(skill2)) {
        print('Found variation match: $skill1 and $skill2 are in the same group');
        return true;
      }
    }

    // Check if one skill is a variation of the other
    for (final entry in skillVariations.entries) {
      if (entry.value.contains(skill1) && entry.key == skill2) {
        print('Found variation match: $skill1 is a variation of $skill2');
        return true;
      }
      if (entry.value.contains(skill2) && entry.key == skill1) {
        print('Found variation match: $skill2 is a variation of $skill1');
        return true;
      }
    }

    return false;
  }

  List<String> _findMissingSkills(List<String> userSkills, List<String> requiredSkills) {
    final matchedSkills = _findMatchedSkills(userSkills, requiredSkills);
    return requiredSkills.where((req) => !matchedSkills.contains(req)).toList();
  }

  // Basic score calculation based on presence of extracted elements
  int _calculateSimplifiedScore(
      List<String> matchedSkills,
      List<String> requiredSkills,
      List<String> requiredExperience, // Using extracted strings directly
      List<String> requiredEducation, // Using extracted strings directly
      UserProfile userProfile) {
    double score = 0;

    // Skills score (simple ratio)
    if (requiredSkills.isNotEmpty) {
      score += (matchedSkills.length / requiredSkills.length) * 40; // 40% weight
    }

    // Experience score (basic check if user has any experience)
    if (requiredExperience.isNotEmpty && userProfile.experience.isNotEmpty) {
      score += 30; // 30% weight - simplified, could be improved
    }

    // Education score (basic check if user has any education)
    if (requiredEducation.isNotEmpty && userProfile.education.isNotEmpty) {
      score += 20; // 20% weight - simplified, could be improved
    }

    // Bonus for having some data
    score += 10; // 10% base

    return score.clamp(0, 100).toInt();
  }

  Future<Map<String, dynamic>> calculateMatchScore({
    required String jobDescription,
    required UserProfile userProfile, // Pass the whole profile
  }) async {
    final extractedData = await _extractJobDetailsWithGemini(jobDescription);

    final requiredSkills = extractedData['skills'] as List<String>? ?? [];
    final requiredExperience = extractedData['experience'] as List<String>? ?? [];
    final requiredEducation = extractedData['education'] as List<String>? ?? [];
    final companyInfo = extractedData['company'] as String?;
    final contactInfo = extractedData['contact'] as String?; // Combined email/contact
    final position = extractedData['position'] as String?;

    final matchedSkills = _findMatchedSkills(userProfile.skills, requiredSkills);
    final missingSkills = _findMissingSkills(userProfile.skills, requiredSkills);

    // Calculate simplified score
    final score = _calculateSimplifiedScore(
      matchedSkills,
      requiredSkills,
      requiredExperience,
      requiredEducation,
      userProfile,
    );

    return {
      'score': score,
      'requiredSkills': requiredSkills,
      'matchedSkills': matchedSkills,
      'missingSkills': missingSkills,
      'requiredExperience': requiredExperience,
      'requiredEducation': requiredEducation,
      'companyInfo': companyInfo,
      'contactInfo': contactInfo,
      'position': position,
      // Optionally return user data if needed by UI, but it's already available
      // 'userExperience': userProfile.workExperience,
      // 'userEducation': userProfile.education,
    };
  }

  // Function to call Gemini API for extracting job details
  Future<Map<String, dynamic>> _extractJobDetailsWithGemini(
    String jobDescription,
  ) async {
    final prompt = '''
    Analyze the following job description and extract the specified details.
    Format the output strictly as a JSON object with the following keys:
    - "skills": A list of required skills (strings).
    - "experience": A list of required experience points (strings), including years if mentioned.
    - "education": A list of required education levels or degrees (strings).
    - "company": The name of the hiring company (string, null if not found).
    - "contact": Any contact information found, like email or phone number (string, null if not found).
    - "position": The exact job title/position being offered (string, null if not found).

    If a specific field cannot be found, return an empty list for lists (skills, experience, education) or null for strings (company, contact, position).

    Job Description:
    ```
    $jobDescription
    ```
    
    JSON Output:
    ''';

    try {
      // Use the injected GeminiService
      final textResponse = await _geminiService.generateContent(prompt) ?? '{}';
      final jsonStart = textResponse.indexOf('{');
      final jsonEnd = textResponse.lastIndexOf('}');
      String jsonString = '{}';
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        jsonString = textResponse.substring(jsonStart, jsonEnd + 1);
      }

      final jsonResponse = jsonDecode(jsonString);

      // Ensure lists are correctly typed
      List<String> skills = jsonResponse['skills'] is List
          ? List<String>.from(jsonResponse['skills'])
          : [];
      List<String> experience = jsonResponse['experience'] is List
          ? List<String>.from(jsonResponse['experience'])
          : [];
      List<String> education = jsonResponse['education'] is List
          ? List<String>.from(jsonResponse['education'])
          : [];

      return {
        'skills': skills,
        'experience': experience,
        'education': education,
        'company': jsonResponse['company'] as String?,
        'contact': jsonResponse['contact'] as String?,
        'position': jsonResponse['position'] as String?,
      };
    } catch (e) {
      print('Error calling Gemini API or parsing JSON: $e');
      // Return default structure on error
      return {
        'skills': [],
        'experience': [],
        'education': [],
        'company': null,
        'contact': null,
        'position': null,
      };
    }
  }
}
