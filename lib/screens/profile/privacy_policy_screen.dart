import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
              ),
              SizedBox(height: 8),
              Text(
                'Welcome to FuelDirect Driver App! Your privacy is very important to us. This policy outlines how we collect, use, and protect your personal data when you use our application.',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.6),
              ),
              SizedBox(height: 24),
              Text(
                '2. Information We Collect',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
              ),
              SizedBox(height: 8),
              Text(
                '• Personal Information: Name, email address, phone number.\n• Location Data: We collect precise location data to coordinate fuel deliveries effectively.\n• Device Information: Device model, operating system, and unique identifiers.',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.6),
              ),
              SizedBox(height: 24),
              Text(
                '3. How We Use Informaiton',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
              ),
              SizedBox(height: 8),
              Text(
                'Data collected is used to optimize fuel drop-offs, track active deliveries, providing in-app guidance, and managing payments/earnings summaries in your dashboard.',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.6),
              ),
              SizedBox(height: 24),
              Text(
                '4. Data Sharing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
              ),
              SizedBox(height: 8),
              Text(
                'We do not sell your personal data. We may share it with verified partners to enhance delivery safety or as required by legal authorities.',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.6),
              ),
              SizedBox(height: 24),
              Text(
                '5. Contact Us',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
              ),
              SizedBox(height: 8),
              Text(
                'For inquiries regarding our privacy policy, please contact us at support@fueldirect.com or through the Help Center in your settings.',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
