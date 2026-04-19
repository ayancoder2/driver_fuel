// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final supabaseUrl = 'https://fsxiioldnxdzidcunmma.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';

  print('Fetching a valid driver from DB...');
  
  final res = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/drivers?select=id,fcm_token&fcm_token=not.is.null&limit=1'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );

  if (res.statusCode != 200) {
    print('Failed to fetch driver: ${res.body}');
    return;
  }

  final drivers = jsonDecode(res.body) as List;
  if (drivers.isEmpty) {
    print('No drivers with FCM tokens found in DB!');
    return;
  }

  final driver = drivers.first;
  final driverId = driver['id'];
  print('Found Driver ID: $driverId');

  print('Calling Edge Function...');
  
  final fnRes = await http.post(
    Uri.parse('$supabaseUrl/functions/v1/send-notification'),
    headers: {
      'Authorization': 'Bearer $anonKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'target_type': 'driver',
      'target_id': driverId,
      'title': 'Test Push',
      'body': 'This is a local diagnostics test!',
      'data': {'type': 'test'}
    }),
  );

  print('Edge Function Response (${fnRes.statusCode}):');
  print(fnRes.body);
}
