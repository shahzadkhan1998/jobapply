import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class ProfileSetupScreen extends StatefulWidget {
  final Function(UserProfile) onProfileSaved;

  const ProfileSetupScreen({super.key, required this.onProfileSaved});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<String> _skills = [];
  final _skillController = TextEditingController();
  final List<WorkExperience> _experiences = [];
  final List<Education> _educations = [];
  final graduationController = TextEditingController();
  final startDate = TextEditingController();
  final gStartDate = DateTime(2017, 10, 10);
  final gEndDate = DateTime(2021, 10, 10);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    if (_skillController.text.isNotEmpty &&
        !_skills.contains(_skillController.text)) {
      setState(() {
        _skills.add(_skillController.text);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _addExperience(BuildContext context) async {
    final companyController = TextEditingController();
    final positionController = TextEditingController();
    DateTime? _startDate;
    DateTime? _endDate;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Experience'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                SizedBox(height: 03),
                TextField(
                  controller: positionController,
                  decoration: const InputDecoration(labelText: 'Position'),
                ),
                ListTile(
                  title: Text(
                    _startDate == null
                        ? 'Select Start Date'
                        : 'Start: ${_startDate!.toLocal()}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    _endDate == null
                        ? 'Select End Date'
                        : 'End: ${_endDate!.toLocal()}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (companyController.text.isNotEmpty &&
                      positionController.text.isNotEmpty &&
                      _startDate != null &&
                      _endDate != null &&
                      _endDate!.isAfter(_startDate!)) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );

    if (result == true) {
      setState(() {
        _experiences.add(
          WorkExperience(
            company: companyController.text,
            position: positionController.text,
            startDate: _startDate!,
            endDate: _endDate,
            responsibilities: [
              'Mobile Application Developer',
              'Flutter developer',
              'Senior Flutter Developer',
            ],
          ),
        );
      });
    }
  }

  void _addEducation(BuildContext context) async {
    final institutionController = TextEditingController();
    final degreeController = TextEditingController();
    final yearController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Education'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: institutionController,
                  decoration: const InputDecoration(labelText: 'Institution'),
                ),
                SizedBox(height: 03),
                TextField(
                  controller: degreeController,
                  decoration: const InputDecoration(labelText: 'Degree'),
                ),
                SizedBox(height: 03),
                TextField(
                  controller: yearController,
                  decoration: const InputDecoration(labelText: 'Year'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (institutionController.text.isNotEmpty &&
                      degreeController.text.isNotEmpty &&
                      yearController.text.isNotEmpty) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );

    if (result == true) {
      setState(() {
        _educations.add(
          Education(
            institution: institutionController.text,
            degree: degreeController.text,
            field: yearController.text,
            graduationDate: gEndDate,
            startDate: gStartDate,
          ),
        );
      });
    }
  }

Future<void> _saveProfile() async {
  if (_formKey.currentState!.validate()) {
    final profile = UserProfile(
       _nameController.text, // Positional argument: name
      _emailController.text, // Positional argument: email
      experience: _experiences, // Named argument
      education: _educations, // Named argument
      contactInfo: ContactInfo(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      ), // Named argument
      skills: _skills, // Named argument
    );

    final profileBox = await Hive.openBox('profile');
    await profileBox.put('userProfile', profile);
    widget.onProfileSaved(profile);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Skills',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillController,
                      decoration: const InputDecoration(
                        labelText: 'Add Skill',
                        prefixIcon: Icon(Icons.code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addSkill,
                    icon: const Icon(Icons.add_circle),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _skills
                        .map(
                          (skill) => Chip(
                            label: Text(skill),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeSkill(skill),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Work Experience',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Column(
                children:
                    _experiences
                        .map(
                          (exp) => ListTile(
                            title: Text('${exp.position} at ${exp.company}'),
                            subtitle: Text(exp.startDate.year.toString()),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:
                                  () =>
                                      setState(() => _experiences.remove(exp)),
                            ),
                          ),
                        )
                        .toList(),
              ),
              ElevatedButton(
                onPressed: () => _addExperience(context),
                child: const Text('Add Experience'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Education',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Column(
                children:
                    _educations
                        .map(
                          (edu) => ListTile(
                            title: Text('${edu.degree} at ${edu.institution}'),
                            subtitle: Text(edu.field),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:
                                  () => setState(() => _educations.remove(edu)),
                            ),
                          ),
                        )
                        .toList(),
              ),
              ElevatedButton(
                onPressed: () => _addEducation(context),
                child: const Text('Add Education'),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
