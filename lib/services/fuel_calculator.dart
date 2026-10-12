class FuelCalculator {
  /// Returns fuel needed in liters
  static double calculateFuelNeeded({
    required double distanceKm,
    required double fuelEfficiencyKmPerLiter,
  }) {
    if (fuelEfficiencyKmPerLiter <= 0) return 0;
    return distanceKm / fuelEfficiencyKmPerLiter;
  }

  /// Returns estimated cost
  static double calculateFuelCost({
    required double fuelLiters,
    required double pricePerLiter,
  }) {
    return fuelLiters * pricePerLiter;
  }
}