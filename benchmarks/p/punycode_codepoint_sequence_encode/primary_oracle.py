"""RFC 3492 Punycode encoder reference for bounded Unicode scalar arrays."""

from __future__ import annotations

from collections.abc import Sequence

MAX_CODEPOINTS = 32
MAX_VALID_INPUT_WORDS = 33
MAX_PARSEABLE_INPUT_WORDS = 34
MAX_VALID_INPUT_LENGTH = MAX_VALID_INPUT_WORDS
MAX_PARSEABLE_INPUT_LENGTH = MAX_PARSEABLE_INPUT_WORDS
MAX_OUTPUT_BYTES = 320
WORKSPACE_BYTES = 320
INVALID_RESULT = -1
OUTPUT_ERROR = -2
BASE = 36
TMIN = 1
TMAX = 26
SKEW = 38
DAMP = 700
INITIAL_BIAS = 72
INITIAL_N = 128
DELIMITER = ord("-")


def _decode_input(values: Sequence[int] | None, input_is_null: bool,
                  input_length: int | None) -> list[int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count = values[0]
    if not 0 <= count <= MAX_CODEPOINTS or len(values) != count + 1:
        return None
    codepoints = list(values[1:])
    if any(cp < 0 or cp > 0x10FFFF or 0xD800 <= cp <= 0xDFFF for cp in codepoints):
        return None
    return codepoints


def _adapt(delta: int, point_count: int, first_time: bool) -> int:
    delta //= DAMP if first_time else 2
    delta += delta // point_count
    k = 0
    while delta > ((BASE - TMIN) * TMAX) // 2:
        delta //= BASE - TMIN
        k += BASE
    return k + (BASE * delta) // (delta + SKEW)


def _digit(value: int) -> int:
    return ord("a") + value if value < 26 else ord("0") + value - 26


def _encode(codepoints: list[int]) -> bytes:
    output = bytearray()
    basic_count = 0
    for cp in codepoints:
        if cp < 0x80:
            output.append(cp)
            basic_count += 1
    if basic_count:
        output.append(DELIMITER)

    n = INITIAL_N
    delta = 0
    bias = INITIAL_BIAS
    handled = basic_count
    while handled < len(codepoints):
        m = min(cp for cp in codepoints if cp >= n)
        delta += (m - n) * (handled + 1)
        n = m
        for cp in codepoints:
            if cp < n:
                delta += 1
            if cp == n:
                q = delta
                k = BASE
                while True:
                    if k <= bias:
                        threshold = TMIN
                    elif k >= bias + TMAX:
                        threshold = TMAX
                    else:
                        threshold = k - bias
                    if q < threshold:
                        output.append(_digit(q))
                        break
                    output.append(_digit(threshold + (q - threshold) % (BASE - threshold)))
                    q = (q - threshold) // (BASE - threshold)
                    k += BASE
                bias = _adapt(delta, handled + 1, handled == basic_count)
                delta = 0
                handled += 1
        delta += 1
        n += 1
    return bytes(output)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_WORDS)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    codepoints = _decode_input(values, input_is_null, input_length)
    if codepoints is None:
        return INVALID_RESULT, b""
    payload = _encode(codepoints)
    if len(payload) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null and payload or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
