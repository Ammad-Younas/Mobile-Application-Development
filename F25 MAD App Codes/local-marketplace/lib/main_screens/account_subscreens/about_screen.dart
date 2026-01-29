import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8C87C),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'GC',
                      style: TextStyle(
                        fontSize: 100,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE8C87C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Get Cars',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF1E3A5F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),
                // Our Mission Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '"Buy, Sell, Reuse"',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A5F),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'A safer, easier marketplace for buying and selling pre-loved goods.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E3A5F),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1E3A5F),
                      height: 1.6,
                    ),
                    children: [
                      TextSpan(
                        text: 'Get Cars',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      TextSpan(
                        text: ' connects buyers and sellers in your neighborhood — helping you find great deals, give items a ',
                      ),
                      TextSpan(
                        text: 'second life',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      TextSpan(
                        text: ', and sell quickly with confidence. From furniture to phones, our community keeps things ',
                      ),
                      TextSpan(
                        text: 'affordable and sustainable',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Contact Information
                _buildContactItem(
                  Icons.linked_camera_outlined,
                  'Instagram: ',
                  '@getcars22',
                  'https://instagram.com/getcars22',
                ),
                const SizedBox(height: 16),
                _buildContactItem(
                  Icons.phone,
                  'Phone No: ',
                  '+91 9234567',
                  'tel:+919234567',
                ),
                const SizedBox(height: 16),
                _buildContactItem(
                  Icons.email,
                  'Email: ',
                  'support@getcars.com',
                  'mailto:support@getcars.com',
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
      IconData icon,
      String label,
      String value,
      String url,
      ) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          debugPrint('Could not launch $url');
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE8C87C),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E3A5F),
                ),
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}