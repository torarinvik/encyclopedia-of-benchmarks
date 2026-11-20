"""Sequential clean-room reference for one bounded brace range expression."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PATTERN_BYTES = 64
MAX_INPUT_LENGTH = 65
MAX_OUTPUT_BYTES = 591
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _endpoint(raw: Sequence[int]) -> tuple[int, bool, int] | None:
    if 1 <= len(raw) <= 4 and all(48 <= byte <= 57 for byte in raw):
        value = 0
        for byte in raw:
            value = value * 10 + byte - 48
        return value, False, len(raw)
    if len(raw) == 1 and (65 <= raw[0] <= 90 or 97 <= raw[0] <= 122):
        return raw[0], True, 1
    return None


def _step(raw: Sequence[int]) -> int | None:
    if not raw:
        return None
    sign = 1
    start = 0
    if raw[0] in (43, 45):
        sign = -1 if raw[0] == 45 else 1
        start = 1
    digits = raw[start:]
    if not digits or any(not 48 <= byte <= 57 for byte in digits):
        return None
    value = 0
    for byte in digits:
        value = min(10000, value * 10 + byte - 48)
    return sign * value if value else None


def _parse(pattern: Sequence[int]) -> tuple[bytes, bytes, int, int, int, bool, int, int] | None:
    if not 1 <= len(pattern) <= MAX_PATTERN_BYTES or any(not 32 <= byte <= 126 for byte in pattern):
        return None
    opens = [i for i, byte in enumerate(pattern) if byte == 123]
    closes = [i for i, byte in enumerate(pattern) if byte == 125]
    if len(opens) != 1 or len(closes) != 1 or opens[0] >= closes[0]:
        return None
    left, right = opens[0], closes[0]
    prefix, suffix = bytes(pattern[:left]), bytes(pattern[right + 1:])
    if len(prefix) + len(suffix) > 32:
        return None
    body = pattern[left + 1:right]
    separators = [i for i in range(len(body) - 1) if body[i] == 46 and body[i + 1] == 46]
    if len(separators) not in (1, 2):
        return None
    if len(separators) == 2 and separators[1] - separators[0] < 2:
        return None
    first = _endpoint(body[:separators[0]])
    if first is None:
        return None
    if len(separators) == 1:
        last = _endpoint(body[separators[0] + 2:])
        explicit_step = None
    else:
        last = _endpoint(body[separators[0] + 2:separators[1]])
        explicit_step = _step(body[separators[1] + 2:])
    same_letter_case = (not first[1] or (65 <= first[0] <= 90) == (65 <= last[0] <= 90)) if last else False
    if (last is None or first[1] != last[1] or not same_letter_case
            or len(separators) == 2 and explicit_step is None):
        return None
    start_value, letters, start_width = first
    end_value, _, end_width = last
    step = explicit_step if explicit_step is not None else (1 if start_value <= end_value else -1)
    if start_value < end_value and step <= 0 or start_value > end_value and step >= 0:
        return None
    if start_value == end_value:
        count = 1
    elif step > 0:
        count = (end_value - start_value) // step + 1
    else:
        count = (start_value - end_value) // -step + 1
    if count > 16:
        return None
    pad_width = max(start_width, end_width) if not letters and (
        pattern[left + 1] == 48 or body[separators[0] + 2] == 48) else 0
    return prefix, suffix, start_value, end_value, step, letters, pad_width, count


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or type(actual_capacity) is not int or actual_capacity < 0
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return INVALID_RESULT, b""
    if (input_is_null or not isinstance(values, (tuple, list))
            or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or input_length is not None and input_length != len(values)
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    declared = values[0]
    pattern = values[1:]
    if (type(declared) is not int or not 1 <= declared <= MAX_PATTERN_BYTES
            or declared != len(pattern)):
        return INVALID_RESULT, b""
    parsed = _parse(pattern)
    if parsed is None:
        return INVALID_RESULT, b""
    prefix, suffix, start, end, step, letters, pad_width, count = parsed
    output = bytearray()
    value = start
    for index in range(count):
        if index:
            output.append(0)
        output.extend(prefix)
        if letters:
            output.append(value)
        else:
            digits = str(value).encode("ascii")
            if pad_width:
                output.extend(b"0" * (pad_width - len(digits)))
            output.extend(digits)
        output.extend(suffix)
        value += step
    if output_is_null or actual_capacity < len(output):
        return OUTPUT_ERROR_RESULT, b""
    return len(output), bytes(output)
