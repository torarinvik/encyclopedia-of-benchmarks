"""Bounded oracle for TheAlgorithms/C-Sharp Shannon-Fano compressor."""

from __future__ import annotations

MAX_TEXT_LENGTH = 16
MAX_SYMBOLS = MAX_TEXT_LENGTH
MAX_CODE_LENGTH = MAX_SYMBOLS - 1
MAX_VALID_INPUT_VALUES = 1 + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1
MAX_COMPRESSED_LENGTH = MAX_TEXT_LENGTH * MAX_CODE_LENGTH
MAX_OUTPUT_BYTES = 1 + MAX_COMPRESSED_LENGTH + 1 + MAX_SYMBOLS * (2 + MAX_CODE_LENGTH)
INVALID_RESULT = -1
OUTPUT_ERROR = -2
SIZE_T_MAX = (1 << 64) - 1


def _compress(text: bytes) -> bytes:
    counts: dict[int, int] = {}
    for symbol in text:
        counts[symbol] = counts.get(symbol, 0) + 1

    if not text:
        compressed = b""
        codes: dict[int, str] = {}
    elif len(counts) == 1:
        symbol = next(iter(counts))
        compressed = b"1" * len(text)
        codes = {symbol: "1"}
    else:
        frequencies = {
            symbol: (1.0 * float(count)) / float(len(text))
            for symbol, count in counts.items()
        }
        codes = {}

        def make_codes(symbols: list[int], prefix: str) -> None:
            if len(symbols) == 1:
                codes[symbols[0]] = prefix
                return

            total = 0.0
            for symbol in symbols:
                total = total + frequencies[symbol]
            capacity = 0.5 * total

            running_weight = 0.0
            left: list[int] = []
            for symbol in symbols:
                frequency = frequencies[symbol]
                if running_weight + frequency <= capacity:
                    running_weight = running_weight + frequency
                    left.append(symbol)

            # Positive frequencies and capacity equal to half the total make
            # both children nonempty for every multi-symbol bounded input.
            if not left or len(left) == len(symbols):
                raise ValueError("split did not partition the symbol list")
            left_set = set(left)
            right = [symbol for symbol in symbols if symbol not in left_set]
            make_codes(left, prefix + "0")
            make_codes(right, prefix + "1")

        make_codes(list(counts), "")
        compressed = "".join(codes[symbol] for symbol in text).encode("ascii")

    output = bytearray((len(compressed),))
    output.extend(compressed)
    output.append(len(codes))
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
    if (
        not isinstance(values, (tuple, list))
        or len(values) > MAX_PARSEABLE_INPUT_VALUES
        or type(input_is_null) is not bool
        or type(input_length) is not int
        or not 0 <= input_length <= MAX_PARSEABLE_INPUT_VALUES
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return None

    if input_is_null:
        return b"" if not values and input_length == 0 else None
    if input_length != len(values) or input_length == 0:
        return None

    text_length = values[0]
    if type(text_length) is not int or not 0 <= text_length <= MAX_TEXT_LENGTH:
        return None
    if input_length != 1 + text_length:
        return None
    text_values = values[1:]
    if any(type(value) is not int or not 0 <= value <= 127 for value in text_values):
        return None
    return bytes(text_values)


def _compute(text: bytes) -> tuple[int, bytes]:
    output = _compress(text)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    return len(output), output


def expected_result(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Return result count and serialized compressed text/table for valid framing."""
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
    """Model null/empty input, framing, and output-buffer errors."""
    effective_length = (
        len(values)
        if input_length is None and isinstance(values, (tuple, list))
        else input_length
    )
    if effective_length is None:
        return INVALID_RESULT, b""
    text = _parse_input(values, input_is_null, effective_length)
    if text is None:
        return INVALID_RESULT, b""
    result, output = _compute(text)
    if result < 0:
        return result, b""
    if type(capacity) is not int or not 0 <= capacity <= SIZE_T_MAX:
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_is_null or capacity < result:
        return OUTPUT_ERROR, b""
    return result, output
