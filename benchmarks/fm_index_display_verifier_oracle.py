"""Direct substring oracle independent of the FM-index display implementation."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT = 32
MAX_INPUT_LENGTH = 36
MAX_OUTPUT_BYTES = 32


def _parse(values: Sequence[int] | None) -> tuple[list[int], int, int, int] | None:
    if (not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_TEXT or len(values) != n + 4:
        return None
    text = list(values[1:n + 1])
    left, right, stride = values[n + 1:n + 4]
    if (any(x < 1 or x > 4 for x in text) or left < 0 or right < left or right >= n
            or stride < 1 or stride > n):
        return None
    return text, left, right, stride


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    text, left, right, _stride = parsed
    output = bytes(text[left:right + 1])
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
