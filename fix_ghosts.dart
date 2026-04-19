// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final supabaseUrl = 'https://fsxiioldnxdzidcunmma.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';

  print('Taking dummy drivers offline so simulation only picks YOU...');

  // Set all EXCEPT khuzaima (c12ede0c-4f1c-4d1e-8129-0e346b301279) to offline
  final res = await http.patch(
    Uri.parse('$supabaseUrl/rest/v1/drivers?id=not.eq.c12ede0c-4f1c-4d1e-8129-0e346b301279'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'status': 'offline'})
  );

  print('Status: ${res.statusCode}');
  
  // Also list online drivers
  final check = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/drivers?select=id,full_name,status&status=eq.online'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );
  print('Online drivers now:');
  print(check.body);
}
