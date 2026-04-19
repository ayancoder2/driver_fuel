// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final supabaseUrl = 'https://fsxiioldnxdzidcunmma.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';

  print('Fetching all drivers with tokens...');
  final res = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/drivers?select=id,full_name,fcm_token&fcm_token=not.is.null'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );

  final drivers = jsonDecode(res.body) as List;
  
  for (var driver in drivers) {
    if (driver['fcm_token'] == null || driver['fcm_token'].toString().isEmpty) continue;
    
    print('Pinging driver: ${driver['full_name']} (${driver['id']})');
    
    final fnRes = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/send-notification'),
      headers: {
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'target_type': 'driver',
        'target_id': driver['id'],
        'title': '🚨 PING TEST: ${driver['full_name']}',
        'body': 'This is to test if your phone vibrates and shows a notification!',
        'data': {'type': 'test'}
      }),
    );
    print('Status: ${fnRes.statusCode}');
    if (fnRes.statusCode == 500) {
      print('ERROR BODY: ${fnRes.body}');
    }
  }
}
