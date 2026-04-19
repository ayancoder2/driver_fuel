// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final supabaseUrl = 'https://fsxiioldnxdzidcunmma.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';

  print('Testing insert into notifications...');
  final res = await http.post(
    Uri.parse('$supabaseUrl/rest/v1/notifications'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'
    },
    body: jsonEncode({
      'driver_id': 'eaa0ba42-68be-4853-b216-58eeda99d691',
      'title': 'Test Insert',
      'body_non_existent': 'This is to test schema',
      'type': 'system',
      'is_read': false
    })
  );

  print('Status: ${res.statusCode}');
  print('Body: ${res.body}');
}
