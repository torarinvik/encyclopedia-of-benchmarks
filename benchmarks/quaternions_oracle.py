"""Binary32 oracle for the pinned C quaternion and Euler-angle routines."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 10  # longest valid input is 9; one trailing value is malformed
MAX_OUTPUT_ELEMENTS = 4
MAX_ANGLE = 3.0
MAX_COMPONENT = 1.0
NORMALIZATION_TOLERANCE = 1e-6
ABSOLUTE_TOLERANCE = 1e-6
RELATIVE_TOLERANCE = 0.0
INVALID_RESULT = -1
OUTPUT_ERROR = -2
F32_TWO = 2.0
F32_HALF = 0.5


def _f32(value: float) -> float:
    """Round a Python number to IEEE-754 binary32, then widen it to Python float."""
    try:
        return struct.unpack("<f", struct.pack("<f", float(value)))[0]
    except OverflowError:
        return math.copysign(math.inf, value)


def _add(left: float, right: float) -> float:
    return _f32(left + right)


def _sub(left: float, right: float) -> float:
    return _f32(left - right)


def _mul(left: float, right: float) -> float:
    return _f32(left * right)


def _sin(value: float) -> float:
    return _f32(math.sin(value))


def _cos(value: float) -> float:
    return _f32(math.cos(value))


def _asin(value: float) -> float:
    return _f32(math.asin(value))


def _atan2(y_value: float, x_value: float) -> float:
    return _f32(math.atan2(y_value, x_value))


def _valid_values(values: Sequence[float] | None) -> list[float] | None:
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
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


def expected_output(values: Sequence[float] | None) -> list[float] | None:
    """Return widened binary32 results, or None for an invalid operation/input."""
    raw = _valid_values(values)
    if raw is None:
        return None

    operation_value = raw[0]
    if operation_value not in (0.0, 1.0, 2.0):
        return None
    operation = int(operation_value)

    if operation == 0:
        if len(raw) != 4 or any(not -MAX_ANGLE <= value <= MAX_ANGLE
                                for value in raw[1:]):
            return None
        yaw, pitch, roll = (_f32(value) for value in raw[1:])
        cy = _cos(_mul(yaw, F32_HALF))
        sy = _sin(_mul(yaw, F32_HALF))
        cp = _cos(_mul(pitch, F32_HALF))
        sp = _sin(_mul(pitch, F32_HALF))
        cr = _cos(_mul(roll, F32_HALF))
        sr = _sin(_mul(roll, F32_HALF))

        w = _add(_mul(_mul(cr, cp), cy), _mul(_mul(sr, sp), sy))
        q1 = _sub(_mul(_mul(sr, cp), cy), _mul(_mul(cr, sp), sy))
        q2 = _add(_mul(_mul(cr, sp), cy), _mul(_mul(sr, cp), sy))
        q3 = _sub(_mul(_mul(cr, cp), sy), _mul(_mul(sr, sp), cy))
        return [w, q1, q2, q3]

    if operation == 1:
        if len(raw) != 5:
            return None
        w, q1, q2, q3 = (_f32(value) for value in raw[1:])
        if any(not -MAX_COMPONENT <= value <= MAX_COMPONENT
               for value in (w, q1, q2, q3)):
            return None

        norm_squared = _add(
            _add(_add(_mul(w, w), _mul(q1, q1)), _mul(q2, q2)),
            _mul(q3, q3),
        )
        if abs(norm_squared - 1.0) > NORMALIZATION_TOLERANCE:
            return None

        # Preserve the executable C source's plus-sign pitch expression. The
        # nearby Doxygen equation has a different sign and is not authoritative.
        pitch_argument = _mul(F32_TWO, _add(_mul(w, q2), _mul(q1, q3)))
        if not -1.0 <= pitch_argument <= 1.0:
            return None

        roll_y = _mul(F32_TWO, _add(_mul(w, q1), _mul(q2, q3)))
        roll_x = _sub(1.0, _mul(F32_TWO, _add(_mul(q1, q1), _mul(q2, q2))))
        pitch = _asin(pitch_argument)
        yaw_y = _mul(F32_TWO, _add(_mul(w, q3), _mul(q1, q2)))
        yaw_x = _sub(1.0, _mul(F32_TWO, _add(_mul(q2, q2), _mul(q3, q3))))
        roll = _atan2(roll_y, roll_x)
        yaw = _atan2(yaw_y, yaw_x)
        return [roll, pitch, yaw]

    if len(raw) != 9 or any(not -MAX_COMPONENT <= value <= MAX_COMPONENT
                            for value in raw[1:]):
        return None
    aw, a1, a2, a3, bw, b1, b2, b3 = (_f32(value) for value in raw[1:])
    w = _sub(_sub(_sub(_mul(aw, bw), _mul(a1, b1)), _mul(a2, b2)), _mul(a3, b3))
    q1 = _sub(_add(_add(_mul(aw, b1), _mul(a1, bw)), _mul(a2, b3)), _mul(a3, b2))
    q2 = _add(_add(_sub(_mul(aw, b2), _mul(a1, b3)), _mul(a2, bw)), _mul(a3, b1))
    q3 = _add(_sub(_add(_mul(aw, b3), _mul(a1, b2)), _mul(a2, b1)), _mul(a3, bw))
    result = [w, q1, q2, q3]
    if any(not -4.0 <= value <= 4.0 for value in result):
        return None
    return result


def expected_abi_result(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Model input validation followed by output-buffer validation."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or not 0 <= output_capacity <= 64
    ):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, []
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    result = expected_output(values)
    if result is None:
        return INVALID_RESULT, []
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return OUTPUT_ERROR, []
    return len(result), result
