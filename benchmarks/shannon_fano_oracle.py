"""Bounded oracle for TheAlgorithms/Java Shannon-Fano code generation."""

from __future__ import annotations

MAX_TEXT_LENGTH = 64
MAX_SYMBOLS = 10
MAX_CODE_LENGTH = MAX_SYMBOLS - 1
MAX_VALID_INPUT_VALUES = 1 + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1
MAX_OUTPUT_BYTES = 1 + MAX_SYMBOLS * (2 + MAX_CODE_LENGTH)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _codes(text: bytes) -> dict[int, str] | None:
    frequencies: dict[int, int] = {}
    for symbol in text:
        frequencies[symbol] = frequencies.get(symbol, 0) + 1
    if not frequencies:
        return {}
    if len(set(frequencies.values())) != len(frequencies):
        return None

    symbols = sorted(frequencies, key=frequencies.__getitem__, reverse=True)
    result: dict[int, str] = {}
    if len(symbols) == 1:
        result[symbols[0]] = "0"
        return result

    def assign(start: int, end: int, prefix: str) -> None:
        if start == end:
            result[symbols[start]] = prefix
            return
        total = sum(frequencies[symbols[index]] for index in range(start, end + 1))
        left_sum = 0
        min_difference: int | None = None
        split_index = start
        for index in range(start, end):
            left_sum += frequencies[symbols[index]]
            right_sum = total - left_sum
            difference = abs(left_sum - right_sum)
            if min_difference is None or difference < min_difference:
                min_difference = difference
                split_index = index
        assign(start, split_index, prefix + "0")
        assign(split_index + 1, end, prefix + "1")

    assign(0, len(symbols) - 1, "")
    return result


def _serialize(codes: dict[int, str]) -> bytes:
    output = bytearray((len(codes),))
    for symbol in sorted(codes):
        code = codes[symbol].encode("ascii")
        output.append(symbol)
        output.append(len(code))
        output.extend(code)
    return bytes(output)


def _parse_input(
        values: tuple[int, ...] | list[int],
        input_is_null: bool,
        input_length: int,
) -> bytes | None:
    if (not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_VALUES
            or type(input_is_null) is not bool
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_VALUES
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_is_null:
        return b"" if not values and input_length == 0 else None
    if input_length != len(values) or input_length == 0:
        return None

    text_length = values[0]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or input_length != 1 + text_length:
        return None
    text_values = values[1:]
    if any(not 0 <= value <= 127 for value in text_values):
        return None
    return bytes(text_values)


def _compute(text: bytes) -> tuple[int, bytes]:
    codes = _codes(text)
    if codes is None:
        return INVALID_RESULT, b""
    output = _serialize(codes)
    if len(codes) > MAX_SYMBOLS or len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    return len(output), output


def expected_result(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Return result count and canonical code-map serialization for valid framing."""
    input_length = len(values) if isinstance(values, (tuple, list)) else -1
    text = _parse_input(values, False, input_length)
    if text is None:
        return INVALID_RESULT, b""
    return _compute(text)


def expected_output(
        values: tuple[int, ...] | list[int],
        capacity: int = MAX_OUTPUT_BYTES,
        output_is_null: bool = False,
        input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, bytes]:
    """Model source null/empty behavior, invalid framing, and output-buffer errors."""
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, b""
    text = _parse_input(values, input_is_null, effective_length)
    if text is None:
        return INVALID_RESULT, b""
    result, output = _compute(text)
    if result < 0:
        return result, b""
    if (type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT_BYTES
            or type(output_is_null) is not bool):
        return INVALID_RESULT, b""
    if output_is_null or capacity < result:
        return OUTPUT_ERROR, b""
    return result, output
