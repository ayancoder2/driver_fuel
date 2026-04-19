import 'package:flutter/material.dart';

import 'delivery_proof_screen.dart';

class ConfirmProtocolScreen extends StatefulWidget {
  final Map<String, dynamic>? order;
  const ConfirmProtocolScreen({super.key, this.order});

  @override
  State<ConfirmProtocolScreen> createState() => _ConfirmProtocolScreenState();
}

class _ConfirmProtocolScreenState extends State<ConfirmProtocolScreen> {
  final List<bool> _selection = [false, false, false];

  bool get _isAllSelected => _selection.every((element) => element);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Confirm Protocol',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Pre-Delivery Protocol',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Complete all items to unlock dispensing',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Protocol Items
              _buildProtocolItem(
                0,
                'Engine Off',
                'Ensure ignition is completely off',
                Icons.local_gas_station,
              ),
              const SizedBox(height: 12),
              _buildProtocolItem(
                1,
                'Fire Extinguisher Ready',
                'Safety equipment within reach',
                Icons.local_gas_station,
              ),
              const SizedBox(height: 12),
              _buildProtocolItem(
                2,
                'Area Safety Confirmed',
                'Clear perimeter, no smoking',
                Icons.local_gas_station,
              ),
              const SizedBox(height: 20),
              // Notice Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8DD).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF4D00).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.warning, color: Color(0xFFFF4D00), size: 18),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'By confirming these checks, you acknowledge that the fueling environment is safe according to regulatory standards.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _isAllSelected
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DeliveryProofScreen(order: widget.order),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D00),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFF2F2F2),
              disabledForegroundColor: const Color(0xFFAAAAAA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Start Dispensing',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isAllSelected ? Icons.arrow_forward : Icons.lock_outline,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolItem(
    int index,
    String title,
    String subtext,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selection[index] = !_selection[index];
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selection[index]
                ? const Color(0xFFFF4D00)
                : const Color(0xFFF2F2F2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8DD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFF4D00), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtext,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
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
                  color: _selection[index]
                      ? const Color(0xFFFF4D00)
                      : const Color(0xFFEEEEEE),
                  width: 2,
                ),
                color: _selection[index]
                    ? const Color(0xFFFF4D00)
                    : Colors.transparent,
              ),
              child: _selection[index]
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
