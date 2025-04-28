import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import hive_flutter for ValueListenableBuilder
import 'package:jobapply/models/user_profile.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/gemini_service.dart';
import '../services/job_matcher.dart';

class JobAnalysisScreen extends StatefulWidget {
  final Function(String, int, String, String) onJobDescriptionAnalyzed;

  const JobAnalysisScreen({super.key, required this.onJobDescriptionAnalyzed});

  @override
  State<JobAnalysisScreen> createState() => _JobAnalysisScreenState();
}

class _JobAnalysisScreenState extends State<JobAnalysisScreen> {
  final _jobDescriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAnalyzing = false;
  int? _matchScore;
  Map<String, dynamic>? _analysisResult; // Store the whole result map
  UserProfile? _profile;
  bool _profileLoaded = false; // Track if profile is loaded
  String? _position;
  String? _company;

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Load profile when the screen initializes
  }

  Future<void> _loadProfile() async {
    final profileBox = await Hive.openBox('profile');
    // Use listenable to react to profile changes
    profileBox.listenable().addListener(() {
      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          _profile = profileBox.get('userProfile') as UserProfile?;
          _profileLoaded = true;
        });
      }
    });
    // Initial load
    if (mounted) {
      setState(() {
        _profile = profileBox.get('userProfile') as UserProfile?;
        _profileLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _jobDescriptionController.dispose();
    // Consider closing the Hive box if it's opened only here
    // Hive.box('profile').listenable().removeListener(_profileListener); // Need to store the listener if removing
    // Hive.close(); // Or manage box opening/closing globally
    super.dispose();
  }

  Future<void> _analyzeJobDescription() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isAnalyzing = true;
      });

      final description = _jobDescriptionController.text;

      if (!_profileLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile still loading... Please wait.'),
          ),
        );
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }

      if (_profile == null) {
        // Show a message or handle the case where the profile isn't loaded/available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete your profile first in the Profile tab.',
            ),
          ),
        );
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }

      // Instantiate GeminiService (replace 'YOUR_API_KEY' with secure handling)
      final geminiService = GeminiService(
        'AIzaSyAEraNDnI7MCYixWCpEfxsH0o3dimmcafw',
      );

      // Calculate match score using the refactored service with injected GeminiService
      final jobMatcher = JobMatcher(geminiService);
      final result = await jobMatcher.calculateMatchScore(
        jobDescription: description,
        userProfile: _profile!,
      );

      setState(() {
        _isAnalyzing = false;
        _matchScore = result['score'] as int?;
        _analysisResult = result; // Store the full result
        _position = result['position'] as String?;
        _company = result['company'] as String?;
      });

      // Call the callback if score is not null
      if (_matchScore != null) {
        widget.onJobDescriptionAnalyzed(
          description,
          _matchScore!,
          _position ?? 'Position not found',
          _company ?? 'Company not found',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste Job Description',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste the full job description to analyze how well your profile matches',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jobDescriptionController,
              decoration: const InputDecoration(
                hintText: 'Paste job description here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 10,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a job description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeJobDescription,
                icon:
                    _isAnalyzing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.analytics),
                label: Text(
                  _isAnalyzing ? 'Analyzing...' : 'Analyze Job Match',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
            if (!_profileLoaded) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Center(child: Text('Loading profile...')),
            ] else if (_profile == null) ...[
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Please create or complete your profile in the Profile tab to enable job matching.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ] else if (_analysisResult != null && _matchScore != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Score: $_matchScore%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              _matchScore! >= 70
                                  ? Colors.green.shade700
                                  : (_matchScore! >= 40
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700),
                        ),
                      ),
                      const Divider(height: 32),
                      _buildSectionTitle('Company Info'),
                      Text(_analysisResult!['companyInfo'] ?? 'Not specified'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Contact Info'),
                      Text(_analysisResult!['contactInfo'] ?? 'Not specified'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Required Skills'),
                      _buildChipList(
                        _analysisResult!['requiredSkills'] as List<String>? ??
                            [],
                        _analysisResult!['matchedSkills'] as List<String>? ??
                            [],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Required Experience'),
                      _buildInfoList(
                        _analysisResult!['requiredExperience']
                                as List<String>? ??
                            [],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Required Education'),
                      _buildInfoList(
                        _analysisResult!['requiredEducation']
                                as List<String>? ??
                            [],
                      ),
                    ],
                  ),
                ),
              ),
              // Removed the separate Match Analysis card as score is shown above
            ],
          ],
        ),
      ),
    );
  }

  // Helper widget for section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper widget to display lists of strings (like experience, education)
  Widget _buildInfoList(List<String> items) {
    if (items.isEmpty) {
      return const Text('Not specified', style: TextStyle(color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('- $item'),
                ),
              )
              .toList(),
    );
  }

  // Helper widget to display skills chips (matched/missing)
  Widget _buildChipList(List<String> required, List<String> matched) {
    if (required.isEmpty) {
      return const Text('Not specified', style: TextStyle(color: Colors.grey));
    }
    final matchedSet = matched.map((s) => s.toLowerCase()).toSet();
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children:
          required.map((skill) {
            final isMatched = matchedSet.contains(skill.toLowerCase());
            return Chip(
              label: Text(skill),
              backgroundColor:
                  isMatched ? Colors.green.shade100 : Colors.red.shade100,
              labelStyle: TextStyle(
                color: isMatched ? Colors.green.shade900 : Colors.red.shade900,
                fontWeight: FontWeight.w500,
              ),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildScoreIndicator() {
    return CircularPercentIndicator(
      radius: 60.0,
      lineWidth: 13.0,
      percent: _matchScore! / 100,
      center: Text(
        '$_matchScore%',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: _getScoreColor(),
        ),
      ),
      progressColor: _getScoreColor(),
    );
  }

  Color _getScoreColor() {
    return _matchScore! >= 70
        ? Colors.green.shade700
        : (_matchScore! >= 40 ? Colors.orange.shade700 : Colors.red.shade700);
  }

  Future<void> _launchEmail() async {
    final contact = _analysisResult!['contactInfo'];
    final email = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    ).firstMatch(contact ?? '')?.group(0);

    if (email != null) {
      final uri = Uri(scheme: 'mailto', path: email, query: "");

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email client')),
        );
      }

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreIndicator(),
          if (_analysisResult!['contactInfo'] != null)
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _launchEmail,
                  icon: const Icon(Icons.email),
                  label: const Text('Contact Employer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact: ${_analysisResult!['contactInfo']}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
        ],
      );
    }
  }
}
