"""Independent direct-window certificate verifier for de Bruijn cycles."""
from __future__ import annotations

from collections.abc import Sequence

MAX_ORDER = 16
MAX_CYCLE_LENGTH = 10_000
MAX_OUTPUT_BYTES = 10_003


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) != 2
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    alphabet, order = values
    if not 2 <= alphabet <= 10 or not 1 <= order <= MAX_ORDER:
        return None
    if alphabet ** order > MAX_CYCLE_LENGTH:
        return None
    return alphabet, order


def verify_result(values: Sequence[int] | None, result: int, output: bytes,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return result == -1 and output == b""
    alphabet, order = parsed
    cycle_length = alphabet ** order
    required = cycle_length + order - 1
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int or capacity < 0
            or output_is_null or capacity < required):
        return result == -2 and output == b""
    if not isinstance(output, (bytes, bytearray)) or result != required or len(output) != required:
        return False
    if any(symbol < 48 or symbol >= 48 + alphabet for symbol in output):
        return False
    if order > 1 and output[cycle_length:] != output[:order - 1]:
        return False
    seen = bytearray(cycle_length)
    for start in range(cycle_length):
        code = 0
        for offset in range(order):
            code = code * alphabet + output[start + offset] - 48
        if seen[code]:
            return False
        seen[code] = 1
    return all(seen)
