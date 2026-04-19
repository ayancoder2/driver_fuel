import 'package:flutter/material.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  int selectedIconIndex = 5; // Black SUV in the screenshot
  int selectedColorIndex = 0; // White in the screenshot
  
  final List<String> carIcons = [
    '🚗', '🚙', '🚕', '🚐',
    '🏎️', '🚓', '🚑', '🚒',
    '🛻'
  ];

  final List<Color> colors = [
    Colors.white,
    Colors.black,
    const Color(0xFFC0C0C0), // Silver
    const Color(0xFF808080), // Gray
    const Color(0xFFD32F2F), // Red
    const Color(0xFF1976D2), // Blue
    const Color(0xFF388E3C), // Green
    const Color(0xFFFBC02D), // Gold/Yellow
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Vehicle',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Choose Icon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              // Icon Grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(carIcons.length, (index) {
                  final bool isSelected = selectedIconIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => selectedIconIndex = index),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          carIcons[index],
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              _buildLabel('Make'),
              _buildTextField(
                hint: 'e.g., Tesla, Toyota, Honda',
                icon: Icons.directions_car_outlined,
              ),
              const SizedBox(height: 24),

              _buildLabel('Model'),
              _buildTextField(
                hint: 'e.g., Model 3, Camry, Civic',
              ),
              const SizedBox(height: 24),

              _buildLabel('Year'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFAAAAAA)),
                    hint: Row(
                      children: const [
                        Icon(Icons.calendar_today_outlined, color: Color(0xFFAAAAAA), size: 20),
                        SizedBox(width: 12),
                      ],
                    ),
                    items: [],
                    onChanged: (value) {},
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel('Color'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(colors.length, (index) {
                  final bool isSelected = selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColorIndex = index),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFF5F5F5),
                          width: 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: isSelected
                          ? Center(
                              child: Icon(
                                Icons.check_circle,
                                color: colors[index] == Colors.white 
                                  ? const Color(0xFFFF6600) 
                                  : Colors.white,
                                size: 24,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected: ${_getColorName()}',
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
              ),
              const SizedBox(height: 24),

              _buildLabel('License Plate'),
              _buildTextField(
                hint: 'ABC 1234',
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 32),

              // Secure Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1E9FF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFFB0B0B0), size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Secure Vehicle Information',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF444444),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your vehicle details help our drivers identify and service the correct vehicle at your location.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5E5E5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check, color: Color(0xFFAAAAAA), size: 20),
                SizedBox(width: 8),
                Text(
                  'Save Vehicle',
                  style: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTextField({required String hint, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          icon: icon != null ? Icon(icon, color: const Color(0xFFAAAAAA), size: 20) : null,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  String _getColorName() {
    switch (selectedColorIndex) {
      case 0: return 'White';
      case 1: return 'Black';
      case 2: return 'Silver';
      case 3: return 'Gray';
      case 4: return 'Red';
      case 5: return 'Blue';
      case 6: return 'Green';
      case 7: return 'Gold';
      default: return '';
    }
  }
}
