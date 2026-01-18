// Create new file: lib/services/otp_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate 6-digit OTP
  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP via email (using Firebase email)
  Future<bool> sendOTPEmail(String email, String otp) async {
    try {
      // Store OTP in Firestore with expiration
      await _firestore.collection('otp_verifications').doc(email).set({
        'otp': otp,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt':
            DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
        'verified': false,
        'attempts': 0,
      });

      // In production, use a service like SendGrid, AWS SES, or Firebase Functions
      // For now, we'll use Firebase Auth's email verification as a workaround
      print('OTP sent to $email: $otp'); // For development

      // TODO: Integrate with email service
      // Example with SendGrid or similar:
      // await sendEmailViaSendGrid(email, otp);

      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(
    String email,
    String enteredOTP,
  ) async {
    try {
      final doc =
          await _firestore.collection('otp_verifications').doc(email).get();

      if (!doc.exists) {
        return {
          'success': false,
          'message': 'OTP not found. Please request again.',
        };
      }

      final data = doc.data()!;
      final storedOTP = data['otp'] as String;
      final expiresAt = DateTime.parse(data['expiresAt']);
      final attempts = (data['attempts'] as int?) ?? 0;
      final verified = data['verified'] as bool;

      // Check if already verified
      if (verified) {
        return {'success': false, 'message': 'OTP already used'};
      }

      // Check expiration
      if (DateTime.now().isAfter(expiresAt)) {
        await _firestore.collection('otp_verifications').doc(email).delete();
        return {
          'success': false,
          'message': 'OTP expired. Please request a new one.',
        };
      }

      // Check attempts
      if (attempts >= 3) {
        await _firestore.collection('otp_verifications').doc(email).delete();
        return {
          'success': false,
          'message': 'Too many failed attempts. Please request a new OTP.',
        };
      }

      // Verify OTP
      if (storedOTP == enteredOTP) {
        await _firestore.collection('otp_verifications').doc(email).update({
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });
        return {'success': true, 'message': 'OTP verified successfully'};
      } else {
        await _firestore.collection('otp_verifications').doc(email).update({
          'attempts': FieldValue.increment(1),
        });
        return {
          'success': false,
          'message': 'Invalid OTP. ${2 - attempts} attempts remaining.',
        };
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'Verification failed. Please try again.',
      };
    }
  }

  // Check if OTP is verified
  Future<bool> isOTPVerified(String email) async {
    try {
      final doc =
          await _firestore.collection('otp_verifications').doc(email).get();
      if (!doc.exists) return false;
      return doc.data()?['verified'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Clean up OTP after successful signup
  Future<void> cleanupOTP(String email) async {
    try {
      await _firestore.collection('otp_verifications').doc(email).delete();
    } catch (e) {
      print('Error cleaning up OTP: $e');
    }
  }

  // Resend OTP
  Future<bool> resendOTP(String email) async {
    try {
      // Delete old OTP
      await _firestore.collection('otp_verifications').doc(email).delete();

      // Generate and send new OTP
      final newOTP = generateOTP();
      return await sendOTPEmail(email, newOTP);
    } catch (e) {
      print('Error resending OTP: $e');
      return false;
    }
  }
}
