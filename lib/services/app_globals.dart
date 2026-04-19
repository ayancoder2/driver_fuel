// Global navigator key — shared between main.dart and NotificationService.
// Keeping this in a dedicated file avoids circular imports.
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
