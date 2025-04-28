import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../blocs/email_bloc.dart';
import '../models/email_tracking.dart';
import '../services/notification_service.dart';

class EmailGenerationScreen extends StatefulWidget {
  final String? jobDescription;
  final int matchScore;
  final String? position;
  final String? company;
  
  const EmailGenerationScreen({
    super.key, 
    this.jobDescription,
    required this.matchScore,
    this.position,
    this.company,
  });

  @override
  State<EmailGenerationScreen> createState() => _EmailGenerationScreenState();
}

class _EmailGenerationScreenState extends State<EmailGenerationScreen> {
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  String? _generatedEmail;
  bool _isGenerating = false;
  bool _isSending = false;
  String? _trackingId;
  bool _showPositionField = false;
  bool _showCompanyField = false;
  bool _showRecipientField = false;
  bool _showSubjectField = false;
  
  @override
  void initState() {
    super.initState();
    _extractDataFromJobDescription();
  }
  
  Future<void> _extractDataFromJobDescription() async {
    if (widget.jobDescription == null) return;
    
    // Extract position
    final positionMatch = RegExp(r'(?:position|job title|role):\s*([^\n]+)', caseSensitive: false)
        .firstMatch(widget.jobDescription!);
    if (positionMatch != null) {
      _positionController.text = positionMatch.group(1)?.trim() ?? '';
    } else {
      _showPositionField = true;
    }
    
    // Extract company
    final companyMatch = RegExp(r'(?:company|organization|employer):\s*([^\n]+)', caseSensitive: false)
        .firstMatch(widget.jobDescription!);
    if (companyMatch != null) {
      _companyController.text = companyMatch.group(1)?.trim() ?? '';
    } else {
      _showCompanyField = true;
    }
    
    // Extract recipient email
    final emailMatch = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')
        .firstMatch(widget.jobDescription!);
    if (emailMatch != null) {
      _recipientController.text = emailMatch.group(0) ?? '';
    } else {
      _showRecipientField = true;
    }
    
    // Generate subject if not found
    if (_positionController.text.isNotEmpty && _companyController.text.isNotEmpty) {
      _subjectController.text = 'Application for ${_positionController.text} position at ${_companyController.text}';
    } else {
      _showSubjectField = true;
    }
    
    // Load any stored data for missing fields
    await _loadStoredData();
  }
  
  Future<void> _loadStoredData() async {
    final box = await Hive.openBox('emailData');
    
    if (_showPositionField) {
      _positionController.text = box.get('lastPosition') ?? '';
    }
    
    if (_showCompanyField) {
      _companyController.text = box.get('lastCompany') ?? '';
    }
    
    if (_showRecipientField) {
      _recipientController.text = box.get('lastRecipient') ?? '';
    }
  }
  
  Future<void> _saveStoredData() async {
    final box = await Hive.openBox('emailData');
    await box.put('lastPosition', _positionController.text);
    await box.put('lastCompany', _companyController.text);
    await box.put('lastRecipient', _recipientController.text);
  }
  
  @override
  void dispose() {
    _positionController.dispose();
    _companyController.dispose();
    _recipientController.dispose();
    _subjectController.dispose();
    super.dispose();
  }
  
  void _generateEmail() {
    // Validate all required fields
    if (_positionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the position')),
      );
      return;
    }

    if (_companyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the company name')),
      );
      return;
    }

    if (_recipientController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the recipient email')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_recipientController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the email subject')),
      );
      return;
    }
    
    setState(() {
      _isGenerating = true;
    });
    
    // Generate a professional email
    context.read<EmailBloc>().add(
      GenerateEmail(
        position: _positionController.text,
        company: _companyController.text,
        skills: ['Flutter', 'Dart', 'Firebase'], // In a real app, get from profile
        matchScore: widget.matchScore,
        recipient: _recipientController.text,
        subject: _subjectController.text,
      )
    );
    
    // Save the data for future use
    _saveStoredData();
  }

  Future<void> _copyToClipboard(String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email copied to clipboard!'))
      );
    }
  }

  Future<void> _sendEmail(String email) async {
    if (_recipientController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter recipient email address')),
      );
      return;
    }
    
    setState(() {
      _isSending = true;
    });
    
    try {
      // Generate tracking ID
      _trackingId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create email tracking record
      final tracking = EmailTracking(
        id: _trackingId!,
        recipient: _recipientController.text,
        subject: _subjectController.text,
        sentAt: DateTime.now(),
        status: EmailStatus.sent,
      );
      
      // Save tracking record
      final box = await Hive.openBox<EmailTracking>('emailTracking');
      await box.put(_trackingId, tracking);
      
      // Send email using platform-specific method
      final uri = Uri(
        scheme: 'mailto',
        path: _recipientController.text,
        queryParameters: {
          'subject': _subjectController.text,
          'body': email,
        },
      );
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        
        // Set up notification for response
        await NotificationService().scheduleEmailResponseCheck(
          trackingId: _trackingId!,
          recipient: _recipientController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email sent successfully!'))
          );
        }
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending email: $e'))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmailBloc, EmailState>(
      listener: (context, state) {
        if (state is EmailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        
        if (state is EmailSuccess) {
          setState(() {
            _generatedEmail = state.email;
            _isGenerating = false;
          });
        }
      },
      builder: (context, state) {
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
                      const Text(
                        'Job Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_showPositionField) ...[
                        TextFormField(
                          controller: _positionController,
                          decoration: const InputDecoration(
                            labelText: 'Position',
                            prefixIcon: Icon(Icons.work),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_showCompanyField) ...[
                        TextFormField(
                          controller: _companyController,
                          decoration: const InputDecoration(
                            labelText: 'Company',
                            prefixIcon: Icon(Icons.business),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_showRecipientField) ...[
                        TextFormField(
                          controller: _recipientController,
                          decoration: const InputDecoration(
                            labelText: 'Recipient Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_showSubjectField) ...[
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Email Subject',
                            prefixIcon: Icon(Icons.subject),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Match Score: ${widget.matchScore}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: state is EmailLoading || _isGenerating ? null : _generateEmail,
                          icon: state is EmailLoading || _isGenerating
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.email),
                          label: Text(state is EmailLoading || _isGenerating ? 'Generating...' : 'Generate Email'),
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
              if (_generatedEmail != null || state is EmailSuccess) ...[  
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generated Email',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              state is EmailSuccess ? state.email : _generatedEmail ?? '',
                              style: const TextStyle(height: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: state is EmailSuccess 
                                  ? () => _copyToClipboard(state.email)
                                  : _generatedEmail != null 
                                      ? () => _copyToClipboard(_generatedEmail!)
                                      : null,
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: state is EmailSuccess 
                                  ? () => _sendEmail(state.email)
                                  : _generatedEmail != null 
                                      ? () => _sendEmail(_generatedEmail!)
                                      : null,
                              icon: _isSending 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.send),
                              label: Text(_isSending ? 'Sending...' : 'Send'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}