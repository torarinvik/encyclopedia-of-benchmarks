"""Independent oracle for the bounded WGS84 radar target calculation."""

from __future__ import annotations

import math

WGS84_A = 6378137.0
WGS84_B = 6356752.314245
WGS84_E_SQ = 1.0 - (WGS84_B**2 / WGS84_A**2)
WGS84_EP_SQ = (WGS84_A**2 - WGS84_B**2) / WGS84_B**2


def _geodetic_to_ecef(lat_deg: float, lon_deg: float, alt_m: float) -> tuple[float, float, float]:
    lat_rad = math.radians(lat_deg)
    lon_rad = math.radians(lon_deg)
    sin_lat = math.sin(lat_rad)
    cos_lat = math.cos(lat_rad)
    n_radius = WGS84_A / math.sqrt(1.0 - WGS84_E_SQ * sin_lat**2)
    x = (n_radius + alt_m) * cos_lat * math.cos(lon_rad)
    y = (n_radius + alt_m) * cos_lat * math.sin(lon_rad)
    z = (n_radius * (1.0 - WGS84_E_SQ) + alt_m) * sin_lat
    return x, y, z


def _ecef_to_geodetic(x_ecef: float, y_ecef: float, z_ecef: float) -> tuple[float, float, float]:
    p = math.sqrt(x_ecef**2 + y_ecef**2)
    if p == 0.0:
        lon_deg = 0.0
        lat_deg = 90.0 if z_ecef > 0.0 else -90.0
        alt_m = abs(z_ecef) - WGS84_B
        return lat_deg, lon_deg, alt_m

    theta = math.atan2(z_ecef * WGS84_A, p * WGS84_B)
    sin_theta = math.sin(theta)
    cos_theta = math.cos(theta)
    lon_rad = math.atan2(y_ecef, x_ecef)
    lat_rad = math.atan2(
        z_ecef + WGS84_EP_SQ * WGS84_B * sin_theta**3,
        p - WGS84_E_SQ * WGS84_A * cos_theta**3,
    )
    sin_lat = math.sin(lat_rad)
    n_radius = WGS84_A / math.sqrt(1.0 - WGS84_E_SQ * sin_lat**2)
    alt_m = (p / math.cos(lat_rad)) - n_radius
    return math.degrees(lat_rad), math.degrees(lon_rad), alt_m


def _enu_to_ecef(
    east: float, north: float, up: float, ref_lat_deg: float, ref_lon_deg: float
) -> tuple[float, float, float]:
    lat_rad = math.radians(ref_lat_deg)
    lon_rad = math.radians(ref_lon_deg)
    sin_lat = math.sin(lat_rad)
    cos_lat = math.cos(lat_rad)
    sin_lon = math.sin(lon_rad)
    cos_lon = math.cos(lon_rad)
    dx = -sin_lon * east - sin_lat * cos_lon * north + cos_lat * cos_lon * up
    dy = cos_lon * east - sin_lat * sin_lon * north + cos_lat * sin_lon * up
    dz = cos_lat * north + sin_lat * up
    return dx, dy, dz


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    """Return the target coordinates for a valid six-value input, else None."""
    if not isinstance(values, (list, tuple)) or len(values) != 6:
        return None
    if any(type(value) not in (int, float) for value in values):
        return None
    lat, lon, alt, azimuth, distance, elevation = (float(value) for value in values)
    if not all(math.isfinite(value) for value in (lat, lon, alt, azimuth, distance, elevation)):
        return None
    if not -80.0 <= lat <= 80.0:
        return None
    if not -180.0 <= lon <= 180.0:
        return None
    if not -1000.0 <= alt <= 10000.0:
        return None
    if not -360.0 <= azimuth <= 360.0:
        return None
    if not 0.0 <= distance <= 200000.0:
        return None
    if not -30.0 <= elevation <= 30.0:
        return None

    az_rad = math.radians(azimuth)
    el_rad = math.radians(elevation)
    east = distance * math.cos(el_rad) * math.sin(az_rad)
    north = distance * math.cos(el_rad) * math.cos(az_rad)
    up = distance * math.sin(el_rad)

    radar_x, radar_y, radar_z = _geodetic_to_ecef(lat, lon, alt)
    dx, dy, dz = _enu_to_ecef(east, north, up, lat, lon)
    target_x = radar_x + dx
    target_y = radar_y + dy
    target_z = radar_z + dz
    target_lat, target_lon, target_alt = _ecef_to_geodetic(target_x, target_y, target_z)
    return [target_lat, target_lon, target_alt]
