"""Independent per-output direct oracle for bounded XOR convolution."""

from collections.abc import Sequence

MODULUS = 998_244_353
MAX_N = 8
MAX_SIZE = 1 << MAX_N
MAX_PARSEABLE_INPUT_LENGTH = 1 + 2 * MAX_SIZE
MAX_OUTPUT_BYTES = 8 * MAX_SIZE


def _parse(values: Sequence[int] | None, input_length: int | None):
    if (values is None or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    exponent = values[0]
    if not 0 <= exponent <= MAX_N:
        return None
    size = 1 << exponent
    if len(values) != 1 + 2 * size:
        return None
    first = values[1:1 + size]
    second = values[1 + size:]
    if any(value < 0 or value >= MODULUS for value in (*first, *second)):
        return None
    return first, second


def evaluate(values: Sequence[int] | None,
             input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    first, second = parsed
    size = len(first)
    coefficients = []
    for output_index in range(size):
        total = 0
        for left_index, left_value in enumerate(first):
            total += left_value * second[left_index ^ output_index]
        coefficients.append(total % MODULUS)
    encoded = b"".join(value.to_bytes(8, "little", signed=True)
                       for value in coefficients)
    return len(encoded), encoded


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
                (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return -1, b""
    if input_is_null:
        return -1, b""
    result, encoded = evaluate(values, input_length)
    if result < 0:
        return result, encoded
    if output_is_null or capacity is not None and capacity < result:
        return -2, b""
    return result, encoded
