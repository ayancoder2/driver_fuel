import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, Icons.home_rounded, 0),
          _buildNavItem(Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, 1),
          _buildNavItem(Icons.directions_car_outlined, Icons.directions_car_filled_rounded, 2),
          _buildNavItem(Icons.person_outline, Icons.person_rounded, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, int index) {
    final bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF6600) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isActive ? filledIcon : outlineIcon,
          color: isActive ? Colors.white : const Color(0xFFAAAAAA),
          size: 28,
        ),
      ),
    );
  }
}
