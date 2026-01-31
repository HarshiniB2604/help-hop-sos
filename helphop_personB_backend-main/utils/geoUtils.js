// Haversine Distance
function getDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // km

  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // distance in km
}

// Bearing (direction angle)
function getBearing(lat1, lon1, lat2, lon2) {
  const dLon = (lon2 - lon1) * (Math.PI / 180);

  lat1 = lat1 * (Math.PI / 180);
  lat2 = lat2 * (Math.PI / 180);

  const y = Math.sin(dLon) * Math.cos(lat2);
  const x =
    Math.cos(lat1) * Math.sin(lat2) -
    Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);

  const brng = Math.atan2(y, x);
  return ((brng * 180) / Math.PI + 360) % 360;
}

// Convert bearing to compass direction
function bearingToDirection(bearing) {
  const directions = [
    "N", "NE", "E", "SE",
    "S", "SW", "W", "NW",
  ];

  const index = Math.round(bearing / 45) % 8;
  return directions[index];
}

module.exports = {
  getDistance,
  getBearing,
  bearingToDirection,
};
