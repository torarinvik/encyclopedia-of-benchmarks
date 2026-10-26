"""Independent direct-substring verifier for the LCP suffix-search profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MAX_PATTERN = 16
MAX_INPUT = 50


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) < n + 2:
        return -1, b""
    text = tuple(values[1:1 + n]); m_at = n + 1; m = values[m_at]
    if not 1 <= m <= MAX_PATTERN or len(values) != m_at + m + 1:
        return -1, b""
    pattern = tuple(values[m_at + 1:])
    if any(not 0 <= x <= 127 for x in text + pattern):
        return -1, b""
    matches = [i for i in range(n) if i + m <= n and text[i:i + m] == pattern]
    matches.sort(key=lambda start: text[start:])
    result = [len(matches), *matches]
    payload = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
