import 'package:flutter/material.dart';

import '../../core/theme.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  static const _findUs = [
    ('Lahore', 'Gulberg III', '+92 42-111-000'),
    ('Islamabad', 'Blue Area', '+92 51-111-000'),
    ('Rawalpindi', 'Saddar Bazaar', '+92 51-222-000'),
    ('Multan', 'Mall Road', '+92 61-111-000'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text('Contact', style: AppTheme.display(size: 20, color: AppColors.red))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Get in touch', style: AppTheme.display(size: 22, color: AppColors.ink)),
                const SizedBox(height: 6),
                Text('Questions, feedback, or catering requests — we read every message.',
                    style: AppTheme.body(color: AppColors.inkSoft)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'YOUR NAME'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'EMAIL ADDRESS'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'YOUR MESSAGE'),
                  maxLines: 4,
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter a message' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Thanks — we'll get back to you soon!"),
                            backgroundColor: AppColors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        _formKey.currentState?.reset();
                      }
                    },
                    child: const Text('SEND CRAVING'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Text('FIND US', style: AppTheme.display(size: 18, color: AppColors.ink)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: _findUs.length,
            itemBuilder: (context, index) {
              final (city, area, phone) = _findUs[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: AppColors.red, size: 18),
                    const SizedBox(height: 6),
                    Text(city, style: AppTheme.body(size: 13, weight: FontWeight.w800)),
                    Text(area, style: AppTheme.body(size: 11, color: AppColors.inkSoft)),
                    const Spacer(),
                    Text(phone, style: AppTheme.body(size: 11, color: AppColors.inkSoft)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
