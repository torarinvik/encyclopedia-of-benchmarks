"""Bounded oracle for the pinned C# geofence distance predicate."""
from __future__ import annotations
import math

MAX_INPUT_LENGTH = 5
INVALID_RESULT = -1
EARTH_RADIUS_METERS = 6_371_010.0

def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return INVALID_RESULT
    lat1, lon1, lat2, lon2, radius_mm = values
    if (not -90_000_000 <= lat1 <= 90_000_000
            or not -90_000_000 <= lat2 <= 90_000_000
            or not -180_000_000 <= lon1 <= 180_000_000
            or not -180_000_000 <= lon2 <= 180_000_000
            or not -1_000_000 <= radius_mm <= 30_000_000_000):
        return INVALID_RESULT
    radians_per_microdegree = math.pi / 180_000_000.0
    phi1, phi2 = lat1 * radians_per_microdegree, lat2 * radians_per_microdegree
    dphi = phi2 - phi1
    dlambda = (lon2 - lon1) * radians_per_microdegree
    sin_lat = math.sin(dphi / 2.0)
    sin_lon = math.sin(dlambda / 2.0)
    hav = sin_lat * sin_lat + math.cos(phi1) * math.cos(phi2) * sin_lon * sin_lon
    hav = max(0.0, min(1.0, hav))
    distance_m = EARTH_RADIUS_METERS * (2.0 * math.atan2(math.sqrt(hav), math.sqrt(1.0 - hav)))
    return int(distance_m <= radius_mm / 1000.0)
