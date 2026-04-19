// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final supabaseUrl = 'https://fsxiioldnxdzidcunmma.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';

  final res = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/drivers?select=id,full_name,fcm_token,status&fcm_token=not.is.null'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );

  final drivers = jsonDecode(res.body) as List;
  print('Total drivers with FCM token: ${drivers.length}');
  for (var d in drivers) {
    print('ID: ${d['id']} | Name: ${d['full_name']} | Status: ${d['status']}');
  }
}
