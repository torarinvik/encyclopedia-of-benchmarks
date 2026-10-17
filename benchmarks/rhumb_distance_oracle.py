"""Oracle for the bounded pinned Rust rhumb-line distance method."""

from __future__ import annotations

import math
from collections.abc import Sequence

EARTH_RADIUS = 6_371_000.0
MIN_LATITUDE = -85.0
MAX_LATITUDE = 85.0
MIN_LONGITUDE = -180.0
MAX_LONGITUDE = 180.0
MAX_VALID_INPUT_LENGTH = 4
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _rhumb_distance(lat1: float, long1: float, lat2: float, long2: float) -> float:
    """Keep the source's conversion, longitude wrap, threshold, and math order."""
    phi1 = lat1 * math.pi / 180.0
    phi2 = lat2 * math.pi / 180.0
    del_phi = phi2 - phi1
    del_lambda = (long2 - long1) * math.pi / 180.0
    if del_lambda > math.pi:
        del_lambda -= 2.0 * math.pi
    elif del_lambda < -math.pi:
        del_lambda += 2.0 * math.pi

    del_psi = math.log(
        math.tan(phi2 / 2.0 + math.pi / 4.0)
        / math.tan(phi1 / 2.0 + math.pi / 4.0)
    )
    q = del_phi / del_psi if abs(del_psi) > 1e-12 else math.cos(phi1)
    return math.sqrt(del_phi**2 + (q * del_lambda) ** 2) * EARTH_RADIUS


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return one distance in meters or the documented slice-I/O error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []
    if not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, []
    if any(type(value) not in (int, float) for value in values):
        return INVALID_RESULT, []
    coordinates = [float(value) for value in values]
    if any(not math.isfinite(value) for value in coordinates):
        return INVALID_RESULT, []
    if len(coordinates) != 4:
        return INVALID_RESULT, []

    lat1, long1, lat2, long2 = coordinates
    if not MIN_LATITUDE <= lat1 <= MAX_LATITUDE:
        return INVALID_RESULT, []
    if not MIN_LATITUDE <= lat2 <= MAX_LATITUDE:
        return INVALID_RESULT, []
    if not MIN_LONGITUDE <= long1 <= MAX_LONGITUDE:
        return INVALID_RESULT, []
    if not MIN_LONGITUDE <= long2 <= MAX_LONGITUDE:
        return INVALID_RESULT, []

    distance = _rhumb_distance(lat1, long1, lat2, long2)
    if not math.isfinite(distance):
        return INVALID_RESULT, []
    output = [distance]
    if output_is_null or (output_capacity is not None and output_capacity < 1):
        return OUTPUT_ERROR, []
    return 1, output
