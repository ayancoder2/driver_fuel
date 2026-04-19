import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'email_service.dart';

class OtpService {
  static final _supabase = Supabase.instance.client;

  static String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  static Future<bool> sendOtp(String email) async {
    final otp = _generateOtp();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));

    try {
      // 1. Save to Supabase
      await _supabase.from('user_otps').insert({
        'email': email,
        'otp': otp,
        'expires_at': expiresAt.toIso8601String(),
        'verified': false,
      });

      // 2. Send Email
      return await EmailService.sendOTP(email, otp);
    } catch (e) {
      debugPrint('Error in sendOtp: $e');
      return false;
    }
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await _supabase
          .from('user_otps')
          .select()
          .eq('email', email)
          .eq('otp', otp)
          .eq('verified', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        // Mark as verified
        await _supabase
            .from('user_otps')
            .update({'verified': true})
            .eq('id', response['id']);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error in verifyOtp: $e');
      return false;
    }
  }
}
