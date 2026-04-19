import 'package:flutter/material.dart';

class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Plan',
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
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF333333),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select how you want to pay for your fuel delivery',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 32),

              // Pay-As-You-Go Plan
              _buildPlanCard(
                icon: Icons.flash_on_rounded,
                iconColor: const Color(0xFF2196F3),
                title: 'Pay-As-You-Go',
                subtitle: 'Perfect for occasional fills',
                price: '\$12',
                priceSuffix: 'delivery fee',
                features: [
                  '\$12 delivery fee',
                  'Pay only for fuel used',
                  'Location-based availability',
                  'No commitment required',
                ],
              ),
              const SizedBox(height: 24),

              // Family Subscription Plan
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildPlanCard(
                    icon: Icons.groups_rounded,
                    iconColor: const Color(0xFFFF6600),
                    title: 'Family Subscription',
                    subtitle: 'Great for regular weekly fills',
                    price: '\$79',
                    priceSuffix: 'per month',
                    features: [
                      'Up to 3 cars included',
                      'Weekly fill-up per car',
                      'Service at up to 2 addresses',
                      'Flexible scheduling',
                      'Tire pressure check',
                      'Windshield cleaning',
                    ],
                    isSelected: true,
                  ),
                  Positioned(
                    top: -12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6600),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'MOST POPULAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Family Elite Plan
              _buildPlanCard(
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFF9C27B0),
                title: 'Family Elite',
                subtitle: 'Premium service for busy families',
                price: '\$129',
                priceSuffix: 'per month',
                features: [
                  'Up to 4 cars included',
                  'Up to 3 fill-ups per week per car',
                  'Service at up to 3 addresses',
                  'Same-day fill-up available',
                  'Possible gas discount',
                  '4th car included free',
                  'Priority support',
                  'All standard services',
                ],
              ),
              const SizedBox(height: 32),

              // Current Order Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Order',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOrderSummaryRow('Fuel Type', ''),
                    const SizedBox(height: 8),
                    _buildOrderSummaryRow('Quantity', 'gallons'),
                    const SizedBox(height: 8),
                    _buildOrderSummaryRow('Fuel Total', '\$'),
                  ],
                ),
              ),
              const SizedBox(height: 100), // Space for button
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0E0E0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Continue',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Color(0xFF888888), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String price,
    required String priceSuffix,
    required List<String> features,
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFF5F5F5),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isSelected ? 10 : 5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(isSelected ? 255 : 40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                priceSuffix,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => _buildFeatureRow(feature)),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFF4CAF50), size: 16),
          const SizedBox(width: 12),
          Text(
            feature,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryRow(String label, String suffix) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Text(
              suffix,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
