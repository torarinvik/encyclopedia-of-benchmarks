"""Binary64 Cramer solve used as an independent reference path."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_COORDINATE_MILLI = 1500
MIN_COORDINATE_MILLI = 900
MIN_UPDATES = 1
MAX_UPDATES = 8
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
MAX_OUTPUT_BYTES = 16
WORKSPACE_BYTES = 128
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _valid(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int] | None:
    if (input_is_null or not isinstance(values, (tuple, list))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    x_milli, y_milli, updates = values
    if (not MIN_COORDINATE_MILLI <= x_milli <= MAX_COORDINATE_MILLI
            or not MIN_COORDINATE_MILLI <= y_milli <= MAX_COORDINATE_MILLI
            or not MIN_UPDATES <= updates <= MAX_UPDATES):
        return None
    return x_milli, y_milli, updates


def _round_nano(value: float) -> int:
    magnitude = math.floor(abs(value) * 1_000_000_000.0 + 0.5)
    return -magnitude if value < 0.0 else magnitude


def coordinates_after_steps(x_milli: int, y_milli: int,
                            updates: int) -> tuple[float, float]:
    x = x_milli / 1000.0
    y = y_milli / 1000.0
    for _ in range(updates):
        first = x * x + y - 3.0
        second = x + y * y - 3.0
        # Form the Jacobian entries, then apply Cramer's rule. This keeps
        # binary64 updates while taking a separate operation path from the
        # primary oracle's simplified inverse-Jacobian expressions.
        j00 = 2.0 * x
        j01 = 1.0
        j10 = 1.0
        j11 = 2.0 * y
        determinant = j00 * j11 - j01 * j10
        delta_x = (first * j11 - j01 * second) / determinant
        delta_y = (j00 * second - first * j10) / determinant
        x, y = x - delta_x, y - delta_y
    return x, y


def expected_output(values: Sequence[int] | None,
                    capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _valid(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool or output_is_null
            or type(capacity) is not int or capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR_RESULT, b""
    x, y = coordinates_after_steps(*parsed)
    return MAX_OUTPUT_BYTES, struct.pack(
        "<qq", _round_nano(x), _round_nano(y))
