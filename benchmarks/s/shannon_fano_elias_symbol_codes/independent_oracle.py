"""Independent exact-fraction bit-expansion reference for SFE codewords."""

from fractions import Fraction

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
SIZE_MAX = (1 << 64) - 1
MIN_SYMBOLS = 1
MAX_SYMBOLS = 8
MIN_WEIGHT = 1
MAX_WEIGHT = 15
MAX_TOTAL_WEIGHT = 120
MAX_CODEWORD_BITS = 8
MAX_VALID_INPUT_LENGTH = 9
MAX_PARSEABLE_INPUT_LENGTH = 10
MAX_OUTPUT_BYTES = 17
WORKSPACE_BYTES = 1024


def _symbol_bits(prefix: int, weight: int, total: int) -> tuple[int, int]:
    bit_length = 1
    probability = Fraction(weight, total)
    while Fraction(1, 1 << (bit_length - 1)) > probability:
        bit_length += 1
    remainder = Fraction(2 * prefix + weight, 2 * total)
    code = 0
    for _ in range(bit_length):
        remainder *= 2
        code <<= 1
        if remainder >= 1:
            code |= 1
            remainder -= 1
    return bit_length, code


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or (input_length is not None and (type(input_length) is not int or not 0 <= input_length <= SIZE_MAX))
            or (capacity is not None and (type(capacity) is not int or not 0 <= capacity <= SIZE_MAX))):
        return -1, b""
    if input_is_null:
        empty_values = values is None or (isinstance(values, (list, tuple)) and len(values) == 0)
        if input_length not in (None, 0) or not empty_values:
            return -1, b""
        return -1, b""
    if (not isinstance(values, (list, tuple)) or len(values) > 10
            or (input_length is not None and input_length != len(values))
            or not 2 <= len(values) <= 9):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""
    n = values[0]
    weights = values[1:]
    if not 1 <= n <= 8 or len(weights) != n or any(not 1 <= weight <= 15 for weight in weights):
        return -1, b""
    total = sum(weights)
    if total > 120:
        return -1, b""

    staged = bytearray([n])
    prefix = 0
    for weight in weights:
        bit_length, code = _symbol_bits(prefix, weight, total)
        staged.extend((bit_length, code << (8 - bit_length)))
        prefix += weight
    if output_is_null or (capacity is not None and capacity < len(staged)):
        return -2, b""
    return len(staged), bytes(staged)
