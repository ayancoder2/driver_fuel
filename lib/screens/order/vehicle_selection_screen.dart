import 'package:flutter/material.dart';
import 'schedule_delivery_screen.dart';

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  int _selectedVehicleIndex = 0;
  int _selectedAddressIndex = 0;

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
          'Vehicle Selection',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Which vehicle needs fuel?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a vehicle from your garage to continue.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              _buildVehicleCard(
                index: 0,
                name: 'Tesla Model 3',
                type: 'Electric',
                imageUrl: 'https://www.kindpng.com/picc/m/112-1120928_tesla-model-3-white-front-view-white-tesla.png',
              ),
              const SizedBox(height: 12),
              _buildVehicleCard(
                index: 1,
                name: 'BMW',
                type: 'Fuel',
                imageUrl: 'https://purepng.com/public/uploads/large/purepng.com-white-bmw-carbmw-car-white-bmw-170152741548680hpe.png',
              ),
              const SizedBox(height: 12),
              _buildVehicleCard(
                index: 2,
                name: 'Tesla Model 3',
                type: 'Electric',
                imageUrl: 'https://www.kindpng.com/picc/m/112-1120928_tesla-model-3-white-front-view-white-tesla.png',
              ),
              const SizedBox(height: 16),
              // Add New Vehicles Button
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEEEEEE),
                    style: BorderStyle.solid, // Note: Dash border requires a custom painter or package
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add, color: Color(0xFFCCCCCC)),
                    SizedBox(width: 8),
                    Text(
                      'Add New Vehicles',
                      style: TextStyle(color: Color(0xFFCCCCCC), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Service Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18, color: Color(0xFFFF6600)),
                    label: const Text(
                      'Add Address',
                      style: TextStyle(color: Color(0xFFFF6600), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAddressCard(
                index: 0,
                title: 'Home',
                address: '123 Main Street, San Francisco, CA 94102',
                isHome: true,
              ),
              const SizedBox(height: 12),
              _buildAddressCard(
                index: 1,
                title: 'Work',
                address: '456 Market Street, San Francisco, CA 94105',
                isHome: false,
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
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              String vehicle = _selectedVehicleIndex == 1 ? 'BMW' : 'Tesla Model 3';
              String location = _selectedAddressIndex == 0 ? 'Home (123 Main St)' : 'Work (456 Market St)';
              
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScheduleDeliveryScreen(
                    vehicleName: vehicle,
                    locationName: location,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Confirm Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard({
    required int index,
    required String name,
    required String type,
    required String imageUrl,
  }) {
    bool isSelected = _selectedVehicleIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicleIndex = index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Image.network(
              imageUrl,
              width: 80,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car, size: 40, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFEEEEEE),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6600),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required int index,
    required String title,
    required String address,
    required bool isHome,
  }) {
    bool isSelected = _selectedAddressIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressIndex = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853), // Green
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isHome ? Icons.home_filled : Icons.business,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFF6600), size: 28)
            else
              const Icon(Icons.circle_outlined, color: Color(0xFFEEEEEE), size: 28),
          ],
        ),
      ),
    );
  }
}
