import 'dart:math';

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _deg2rad(double deg) => deg * pi / 180;

double? feeFromDistance(double km) {
  if (km <= 3) return 19;
  if (km <= 6) return 29;
  if (km <= 9) return 39;
  if (km <= 12) return 59;
  return null;
}

const double FREE_GROCERY = 349;
const double FREE_FOOD = 399;

bool qualifiesForFree(double cartAmount, bool isGrocery) {
  final threshold = isGrocery ? FREE_GROCERY : FREE_FOOD;
  return cartAmount >= threshold;
}
