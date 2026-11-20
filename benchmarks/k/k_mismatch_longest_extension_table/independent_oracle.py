"""Direct mismatch-scan oracle for the longest-extension table."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_K = 4
MAX_PARSEABLE_INPUT_LENGTH = 67
MAX_OUTPUT_BYTES = 320
WORKSPACE_BYTES = 8192


def _read_frame(values: Sequence[int] | None, input_length: int | None):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size != len(values):
        return None
    size_n, errors = values[0], values[1]
    if not 1 <= size_n <= MAX_N or not 0 <= errors <= MAX_K or size != size_n + 2:
        return None
    symbols = values[2:]
    if any(symbol < 0 or symbol > 25 for symbol in symbols):
        return None
    return symbols, errors


def _direct_table(text: Sequence[int], budget: int) -> bytes:
    n = len(text)
    result = bytearray()
    for suffix_start in range(n):
        available = n - suffix_start
        for allowed in range(budget + 1):
            mismatches = 0
            length = 0
            while length < available:
                if text[length] != text[suffix_start + length]:
                    mismatches += 1
                    if mismatches > allowed:
                        break
                length += 1
            result.append(length)
    return bytes(result)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if input_length is not None and (type(input_length) is not int
                                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    parsed = _read_frame(values, input_length)
    if parsed is None:
        return -1, b""
    text, budget = parsed
    payload = _direct_table(text, budget)
    if payload and (output_is_null or (capacity is not None and capacity < len(payload))):
        return -2, b""
    return len(payload), payload
