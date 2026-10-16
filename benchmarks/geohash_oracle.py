"""Bounded 12-character C# geohash encoder oracle."""
from __future__ import annotations

ALPHABET = "0123456789bcdefghjkmnpqrstuvwxyz"
MAX_INPUT_LENGTH = 2

def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1, b""
    latitude, longitude = values
    if not -90_000_000 <= latitude <= 90_000_000 or not -180_000_000 <= longitude <= 180_000_000:
        return -1, b""
    lat = latitude / 1_000_000.0
    lon = longitude / 1_000_000.0
    lat_lo, lat_hi = -90.0, 90.0
    lon_lo, lon_hi = -180.0, 180.0
    encode_lon = True
    bit = value = 0
    chars: list[str] = []
    while len(chars) < 12:
        if encode_lon:
            mid = (lon_lo + lon_hi) / 2.0
            if lon > mid:
                value |= 1 << (4 - bit)
                lon_lo = mid
            else:
                lon_hi = mid
        else:
            mid = (lat_lo + lat_hi) / 2.0
            if lat > mid:
                value |= 1 << (4 - bit)
                lat_lo = mid
            else:
                lat_hi = mid
        encode_lon = not encode_lon
        if bit < 4:
            bit += 1
        else:
            chars.append(ALPHABET[value])
            bit = value = 0
    output = "".join(chars).encode("ascii")
    return len(output), output
