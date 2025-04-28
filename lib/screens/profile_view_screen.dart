import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class ProfileViewScreen extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEditProfile;
  final Function(List<String>) onEditSkills;
  final Function(List<WorkExperience>) onEditExperience;
  final Function(List<Education>) onEditEducation;

  const ProfileViewScreen({
    super.key,
    required this.profile,
    required this.onEditProfile,
    required this.onEditSkills,
    required this.onEditExperience,
    required this.onEditEducation,
  });

  Future<void> _saveSkillsToStorage(List<String> skills) async {
    final box = await Hive.openBox('profile');
    await box.put('skills', skills);
  }

  Future<void> _saveExperienceToStorage(List<WorkExperience> experience) async {
    final box = await Hive.openBox('profile');
    await box.put('experience', experience);
  }

  Future<void> _saveEducationToStorage(List<Education> education) async {
    final box = await Hive.openBox('profile');
    await box.put('education', education);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.contactInfo.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(profile.contactInfo.email),
                            Text(profile.contactInfo.phone),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onEditProfile,
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Profile',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Skills',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => _showEditSkillsDialog(context),
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Skills',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        profile.skills
                            .map(
                              (skill) => Chip(
                                label: Text(skill),
                                backgroundColor: Colors.blue.shade100,
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Work Experience',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => _showEditExperienceDialog(context),
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Experience',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (profile.experience.isEmpty)
                    const Text('No work experience added yet')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: profile.experience.length,
                      itemBuilder: (context, index) {
                        final exp = profile.experience[index];
                        return ListTile(
                          title: Text(exp.position),
                          subtitle: Text(exp.company),
                          trailing: Text(
                            '${exp.startDate.year} - ${exp.endDate?.year ?? 'Present'}',
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Education',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => _showEditEducationDialog(context),
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Education',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (profile.education.isEmpty)
                    const Text('No education added yet')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: profile.education.length,
                      itemBuilder: (context, index) {
                        final edu = profile.education[index];
                        return ListTile(
                          title: Text(edu.degree),
                          subtitle: Text(edu.institution),
                          trailing: Text(
                            '${edu.startDate?.year ?? ''} - ${edu.endDate?.year ?? 'Present'}',
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSkillsDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController(
      text: profile.skills.join(', '),
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Skills'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter skills separated by commas',
            labelText: 'Skills',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final skills = controller.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              
              // Update UI
              onEditSkills(skills);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditExperienceDialog(BuildContext context) async {
    final List<WorkExperience> experiences = List.from(profile.experience);
    final TextEditingController positionController = TextEditingController();
    final TextEditingController companyController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Work Experience'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  hintText: 'Enter your position',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  hintText: 'Enter company name',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(startDate?.toString() ?? 'Select'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          startDate = date;
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(endDate?.toString() ?? 'Present'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          endDate = date;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (positionController.text.isNotEmpty && 
                  companyController.text.isNotEmpty && 
                  startDate != null) {
                experiences.add(WorkExperience(
                  position: positionController.text,
                  company: companyController.text,
                  startDate: startDate!,
                  endDate: endDate,
                  responsibilities: [],
                ));
                
                // Save to local storage
                await _saveExperienceToStorage(experiences);
                
                // Update UI
                onEditExperience(experiences);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditEducationDialog(BuildContext context) async {
    final List<Education> education = List.from(profile.education);
    final TextEditingController degreeController = TextEditingController();
    final TextEditingController institutionController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Education'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: degreeController,
                decoration: const InputDecoration(
                  labelText: 'Degree',
                  hintText: 'Enter your degree',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: institutionController,
                decoration: const InputDecoration(
                  labelText: 'Institution',
                  hintText: 'Enter institution name',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(startDate?.toString() ?? 'Select'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          startDate = date;
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(endDate?.toString() ?? 'Present'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          endDate = date;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (degreeController.text.isNotEmpty && 
                  institutionController.text.isNotEmpty && 
                  startDate != null) {
                education.add(Education(
                  degree: degreeController.text,
                  institution: institutionController.text,
                  startDate: startDate ?? DateTime.now(),
                  endDate: endDate,
                  field: degreeController.text,
                  graduationDate: endDate ?? DateTime.now(),
                ));
                
                // Save to local storage
                await _saveEducationToStorage(education);
                
                // Update UI
                onEditEducation(education);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
