import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FuelInfoCard extends StatelessWidget {
  final double distanceKm;
  final double fuelLiters;
  final double fuelCost;
  final String durationText;

  const FuelInfoCard({
    super.key,
    required this.distanceKm,
    required this.fuelLiters,
    required this.fuelCost,
    required this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##0', 'en_US');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildItem(Icons.route, '${distanceKm.toStringAsFixed(1)} km', 'Distance'),
              _buildItem(Icons.local_gas_station, '${fuelLiters.toStringAsFixed(2)} L', 'Fuel'),
              _buildItem(Icons.access_time, durationText, 'Time'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white38),
          const SizedBox(height: 8),
          Text(
            'Estimated Cost: ${currency.format(fuelCost)} MMK',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}