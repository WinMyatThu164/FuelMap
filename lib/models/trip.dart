class Trip {
  final String? id;
  final String origin;
  final String destination;
  final double distanceKm;
  final double fuelNeededLiters;
  final double fuelCost;
  final double fuelEfficiency;
  final double fuelPrice;
  final DateTime createdAt;

  Trip({
    this.id,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.fuelNeededLiters,
    required this.fuelCost,
    required this.fuelEfficiency,
    required this.fuelPrice,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'distance_km': distanceKm,
      'fuel_needed_liters': fuelNeededLiters,
      'fuel_cost': fuelCost,
      'fuel_efficiency': fuelEfficiency,
      'fuel_price': fuelPrice,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id']?.toString(),
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      fuelNeededLiters: (json['fuel_needed_liters'] as num?)?.toDouble() ?? 0.0,
      fuelCost: (json['fuel_cost'] as num?)?.toDouble() ?? 0.0,
      fuelEfficiency: (json['fuel_efficiency'] as num?)?.toDouble() ?? 0.0,
      fuelPrice: (json['fuel_price'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}