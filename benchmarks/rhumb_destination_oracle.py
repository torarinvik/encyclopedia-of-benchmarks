"""Oracle for the bounded pinned Rust rhumb-line destination method."""

from __future__ import annotations

import math
from collections.abc import Sequence

EARTH_RADIUS = 6_371_000.0
MIN_LATITUDE = -80.0
MAX_LATITUDE = 80.0
MIN_LONGITUDE = -180.0
MAX_LONGITUDE = 180.0
MIN_DISTANCE = 0.0
MAX_DISTANCE = 300_000.0
MIN_BEARING = 0.0
MAX_BEARING = 360.0
MAX_VALID_INPUT_LENGTH = 4
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _rhumb_destination(
    latitude: float, longitude: float, distance: float, bearing: float
) -> list[float]:
    """Keep the source's operation order and intentionally unnormalized longitude."""
    delta = distance / EARTH_RADIUS
    phi1 = latitude * math.pi / 180.0
    lambda1 = longitude * math.pi / 180.0
    theta = bearing * math.pi / 180.0

    del_phi = delta * math.cos(theta)
    phi2 = min(max(phi1 + del_phi, -math.pi / 2.0), math.pi / 2.0)
    del_psi = math.log(
        math.tan(phi2 / 2.0 + math.pi / 4.0)
        / math.tan(phi1 / 2.0 + math.pi / 4.0)
    )
    q = del_phi / del_psi if abs(del_psi) > 1e-12 else math.cos(phi1)
    del_lambda = delta * math.sin(theta) / q
    lambda2 = lambda1 + del_lambda
    return [phi2 * 180.0 / math.pi, lambda2 * 180.0 / math.pi]


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return destination latitude/longitude in degrees or the slice-I/O error."""
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
    arguments = [float(value) for value in values]
    if any(not math.isfinite(value) for value in arguments):
        return INVALID_RESULT, []
    if len(arguments) != 4:
        return INVALID_RESULT, []

    latitude, longitude, distance, bearing = arguments
    if not MIN_LATITUDE <= latitude <= MAX_LATITUDE:
        return INVALID_RESULT, []
    if not MIN_LONGITUDE <= longitude <= MAX_LONGITUDE:
        return INVALID_RESULT, []
    if not MIN_DISTANCE <= distance <= MAX_DISTANCE:
        return INVALID_RESULT, []
    if not MIN_BEARING <= bearing <= MAX_BEARING:
        return INVALID_RESULT, []

    output = _rhumb_destination(latitude, longitude, distance, bearing)
    if any(not math.isfinite(value) for value in output):
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < 2):
        return OUTPUT_ERROR, []
    return 2, output
