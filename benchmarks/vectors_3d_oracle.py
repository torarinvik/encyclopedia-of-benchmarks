"""Independent binary32-faithful oracle for the bounded 3D vector operations."""

from __future__ import annotations

import math
import struct

MAX_COMPONENT = 1_000_000.0
EPSILON = 1e-9
UNARY_ARITIES = {4: 4, 5: 4, 6: 4}
BINARY_ARITIES = {0: 7, 1: 7, 2: 7, 3: 7, 7: 7}


def _f32(value: float) -> float:
    """Round a Python float to the source struct's IEEE 754 binary32 field."""
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _finite_inputs(values: object) -> list[float] | None:
    if not isinstance(values, (list, tuple)):
        return None
    converted: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            number = float(value)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(number):
            return None
        converted.append(number)
    return converted


def _dot(a: tuple[float, float, float], b: tuple[float, float, float]) -> float:
    result = _f32(a[0] * b[0])
    result = _f32(result + _f32(a[1] * b[1]))
    result = _f32(result + _f32(a[2] * b[2]))
    return result


def _norm(vector: tuple[float, float, float]) -> float:
    return _f32(math.sqrt(_dot(vector, vector)))


def expected_result(values: object) -> tuple[float, ...] | None:
    """Return widened source results for a valid operation, or ``None`` if invalid.

    Operation codes are 0 add, 1 subtract, 2 dot, 3 cross, 4 norm, 5 unit,
    6 cross-product matrix, and 7 angle. Vector arithmetic follows the C source's
    float evaluation order and rounding; ``get_angle`` retains its NaN outcomes.
    """
    converted = _finite_inputs(values)
    if converted is None or not converted:
        return None
    operation_value = converted[0]
    if operation_value not in range(8):
        return None
    operation = int(operation_value)
    if operation_value != operation:
        return None
    required_length = UNARY_ARITIES.get(operation, BINARY_ARITIES.get(operation))
    if required_length is None or len(converted) != required_length:
        return None
    components = converted[1:]
    if any(abs(value) > MAX_COMPONENT for value in components):
        return None
    rounded = [_f32(value) for value in components]
    a = (rounded[0], rounded[1], rounded[2])
    b = (rounded[3], rounded[4], rounded[5]) if operation in BINARY_ARITIES else None

    if operation == 0:
        assert b is not None
        return tuple(_f32(a[index] + b[index]) for index in range(3))
    if operation == 1:
        assert b is not None
        return tuple(_f32(a[index] - b[index]) for index in range(3))
    if operation == 2:
        assert b is not None
        return (_dot(a, b),)
    if operation == 3:
        assert b is not None
        return (
            _f32(_f32(a[1] * b[2]) - _f32(a[2] * b[1])),
            _f32(_f32(-a[0] * b[2]) + _f32(a[2] * b[0])),
            _f32(_f32(a[0] * b[1]) - _f32(a[1] * b[0])),
        )
    if operation == 4:
        return (_norm(a),)
    if operation == 5:
        norm = _norm(a)
        if abs(norm) < EPSILON:
            return (0.0, 0.0, 0.0)
        if norm == _f32(1.0):
            # The source's zero-initialized result is never populated in this branch.
            return (0.0, 0.0, 0.0)
        return tuple(_f32(component / norm) for component in a)
    if operation == 6:
        return (
            0.0, _f32(-a[2]), a[1],
            a[2], 0.0, _f32(-a[0]),
            _f32(-a[1]), a[0], 0.0,
        )

    assert operation == 7 and b is not None
    norm_a, norm_b = _norm(a), _norm(b)
    if abs(norm_a) < EPSILON or abs(norm_b) < EPSILON:
        return (math.nan,)
    dot = _dot(a, b)
    denominator = _f32(norm_a * norm_b)
    ratio = _f32(dot / denominator)
    try:
        return (math.acos(ratio),)
    except ValueError:
        # Match C acos for an unclamped argument outside [-1, 1].
        return (math.nan,)


def expected_output(values: object) -> tuple[int, tuple[float, ...]]:
    """Return `(element_count, values)` or `(-1, ())` for invalid input."""
    result = expected_result(values)
    return (-1, ()) if result is None else (len(result), result)
