"""Independent oracle for C# GeoLocation's spherical meter distance."""
from __future__ import annotations

import math

MAX_INPUT_LENGTH = 4
EARTH_RADIUS_METERS = 6_371_010.0


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return None
    lat1, lon1, lat2, lon2 = map(float, values)
    if (not -90.0 <= lat1 <= 90.0 or not -90.0 <= lat2 <= 90.0
            or not -180.0 <= lon1 <= 180.0 or not -180.0 <= lon2 <= 180.0):
        return None
    radians = math.pi / 180.0
    lat1 *= radians
    lon1 *= radians
    lat2 *= radians
    lon2 *= radians
    diff_lat = lat2 - lat1
    diff_lon = lon2 - lon1
    sin_lat = math.sin(diff_lat / 2.0)
    sin_lon = math.sin(diff_lon / 2.0)
    haversine = (sin_lat * sin_lat
                 + math.cos(lat1) * math.cos(lat2) * sin_lon * sin_lon)
    if not 0.0 <= haversine <= 1.0:
        return None
    central_angle = 2.0 * math.atan2(math.sqrt(haversine), math.sqrt(1.0 - haversine))
    return [EARTH_RADIUS_METERS * central_angle]
