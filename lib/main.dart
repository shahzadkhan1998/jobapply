import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'blocs/email_bloc.dart';
import 'services/firebase_service.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'config/config.dart';
import 'services/gemini_service.dart';
import 'models/user_profile.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/profile_view_screen.dart';
import 'screens/job_analysis_screen.dart';
import 'screens/email_generation_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Hive
    await Hive.initFlutter();
    
    // Initialize services
    await HiveService().initialize();
    await FirebaseService().initialize();
    await NotificationService().initialize();
    await NotificationService().setListeners();
    final geminiService = GeminiService(AppConfig.geminiApiKey);

    runApp(
      RepositoryProvider<GeminiService>(
        create: (context) => geminiService,
        child: const JobAssistantApp(),
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error during app initialization: $e');
    }
    rethrow;
  }
}

class JobAssistantApp extends StatelessWidget {
  const JobAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp
    (
      debugShowCheckedModeBanner: false,
      title: 'Job Application Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue.shade700,
          secondary: Colors.teal,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: BlocProvider(
        create: (context) => EmailBloc(context.read<GeminiService>()),
        child: const JobAssistantDashboard(),
      ),
    );
  }
}

class JobAssistantDashboard extends StatefulWidget {
  const JobAssistantDashboard({super.key});

  @override
  State<JobAssistantDashboard> createState() => _JobAssistantDashboardState();
}

class _JobAssistantDashboardState extends State<JobAssistantDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  UserProfile? _userProfile;
  String? _jobDescription;
  int? _matchScore;
  String? _position;
  String? _company;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final box = await Hive.openBox('profile');
      final storedProfile = box.get('userProfile') as UserProfile?;
      
      if (storedProfile != null) {
        setState(() {
          _userProfile = storedProfile;
        });
      } else {
        setState(() {
          _userProfile = null; // Set to null to show the profile setup screen first time
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _userProfile = null;
      });
    }
  }
  
  void _navigateToPage(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleEditSkills(List<String> skills) async {
    if (_userProfile != null) {
      final updatedProfile = _userProfile!.copyWith(skills: skills);
      final box = await Hive.openBox('profile');
      await box.put('userProfile', updatedProfile);
      setState(() {
        _userProfile = updatedProfile;
      });
    }
  }

  void _handleEditExperience(List<WorkExperience> experience) {
    setState(() {
      _userProfile = _userProfile?.copyWith(experience: experience);
    });
  }

  void _handleEditEducation(List<Education> education) {
    setState(() {
      _userProfile = _userProfile?.copyWith(education: education);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Application Assistant'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _userProfile == null 
              ? ProfileSetupScreen(onProfileSaved: (profile) {
                  setState(() {
                    _userProfile = profile;
                  });
                })
              : ProfileViewScreen(
                  profile: _userProfile!,
                  onEditProfile: () {
                    // Show edit profile screen
                  },
                  onEditSkills: _handleEditSkills,
                  onEditExperience: _handleEditExperience,
                  onEditEducation: _handleEditEducation,
                ),
          JobAnalysisScreen(
            onJobDescriptionAnalyzed: (description, score, position, company) {
              setState(() {
                _jobDescription = description;
                _matchScore = score;
                _position = position;
                _company = company;
              });
              // Automatically navigate to email screen if analysis is successful
              if (score != null) {
                _navigateToPage(2);
              }
            },
          ),
          EmailGenerationScreen(
            jobDescription: _jobDescription,
            matchScore: _matchScore ?? 0,
            position: _position,
            company: _company,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateToPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Job Analysis',
          ),
          NavigationDestination(
            icon: Icon(Icons.email_outlined),
            selectedIcon: Icon(Icons.email),
            label: 'Email',
          ),
        ],
      ),
    );
  }
}