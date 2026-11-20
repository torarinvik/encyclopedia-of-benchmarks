"""Index-based independent reference for bounded brace range expansion."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OUTPUT_BYTES = 591
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _number(token: Sequence[int]) -> tuple[int, bool, int] | None:
    if 1 <= len(token) <= 4 and all(48 <= byte <= 57 for byte in token):
        return int(bytes(token)), False, len(token)
    if len(token) == 1 and (65 <= token[0] <= 90 or 97 <= token[0] <= 122):
        return token[0], True, 1
    return None


def _plan(pattern: Sequence[int]):
    if not 1 <= len(pattern) <= 64 or any(byte < 32 or byte > 126 for byte in pattern):
        return None
    try:
        left = pattern.index(123)
        if pattern.index(123, left + 1) >= 0:
            return None
    except ValueError:
        return None
    try:
        right = pattern.index(125)
        if pattern.index(125, right + 1) >= 0 or right < left:
            return None
    except ValueError:
        return None
    if any(byte in (123, 125) for byte in pattern[:left] + pattern[right + 1:]):
        return None
    prefix = bytes(pattern[:left])
    suffix = bytes(pattern[right + 1:])
    if len(prefix) + len(suffix) > 32:
        return None
    body = bytes(pattern[left + 1:right]).decode("ascii")
    parts = body.split("..")
    if len(parts) not in (2, 3):
        return None
    a = _number(parts[0].encode("ascii"))
    b = _number(parts[1].encode("ascii"))
    if (a is None or b is None or a[1] != b[1]
            or a[1] and ((65 <= a[0] <= 90) != (65 <= b[0] <= 90))):
        return None
    if len(parts) == 3:
        text = parts[2]
        sign = -1 if text.startswith("-") else 1
        digits = text[1:] if text[:1] in ("+", "-") else text
        if not digits or not digits.isascii() or not digits.isdigit():
            return None
        magnitude = min(10000, int(digits))
        if magnitude == 0:
            return None
        step = sign * magnitude
    else:
        step = 1 if a[0] <= b[0] else -1
    start, end = a[0], b[0]
    if start < end and step <= 0 or start > end and step >= 0:
        return None
    if start == end:
        term_count = 1
    else:
        term_count = abs(end - start) // abs(step) + 1
    if term_count > 16:
        return None
    padded = max(a[2], b[2]) if not a[1] and (
        parts[0].startswith("0") or parts[1].startswith("0")) else 0
    return prefix, suffix, start, step, a[1], padded, term_count


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or type(actual_capacity) is not int or actual_capacity < 0
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= 65)):
        return -1, b""
    if (input_is_null or not isinstance(values, (tuple, list))
            or len(values) < 2 or len(values) > 65
            or input_length is not None and input_length != len(values)
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    if type(values[0]) is not int or not 1 <= values[0] <= 64 or values[0] != len(values) - 1:
        return -1, b""
    plan = _plan(values[1:])
    if plan is None:
        return -1, b""
    prefix, suffix, start, step, letters, padded, term_count = plan
    words = []
    for index in range(term_count):
        value = start + index * step
        if letters:
            token = bytes((value,))
        else:
            token = str(value).encode("ascii")
            if padded:
                token = b"0" * (padded - len(token)) + token
        words.append(prefix + token + suffix)
    encoded = b"\0".join(words)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or actual_capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
