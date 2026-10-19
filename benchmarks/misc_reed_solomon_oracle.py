"""Independent reference model for the bounded shortened RS(204,188) profile."""

from __future__ import annotations

MESSAGE_BYTES = 188
PARITY_BYTES = 16
CODEWORD_BYTES = MESSAGE_BYTES + PARITY_BYTES
MAX_ERROR_COUNT = 1
MAX_INPUT_VALUES = MESSAGE_BYTES + 1 + 2 * MAX_ERROR_COUNT
MAX_VALID_INPUT_VALUES = MAX_INPUT_VALUES
MAX_PARSEABLE_INPUT_VALUES = MAX_INPUT_VALUES
MAX_OUTPUT_BYTES = CODEWORD_BYTES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _field_tables() -> tuple[list[int], list[int]]:
    """Build GF(256) tables from the pinned source's polynomial 0x11d."""
    alpha_to = [0] * 256
    index_of = [-1] * 256
    mask = 1
    alpha_to[8] = 0
    for exponent in range(8):
        alpha_to[exponent] = mask
        index_of[mask] = exponent
        if (0x11D >> exponent) & 1:
            alpha_to[8] ^= mask
        mask <<= 1
    index_of[alpha_to[8]] = 8
    mask >>= 1
    for exponent in range(9, 255):
        previous = alpha_to[exponent - 1]
        if previous >= mask:
            alpha_to[exponent] = alpha_to[8] ^ ((previous ^ mask) << 1)
        else:
            alpha_to[exponent] = previous << 1
        index_of[alpha_to[exponent]] = exponent
    index_of[0] = -1
    return alpha_to, index_of


def _generator(alpha_to: list[int], index_of: list[int]) -> list[int]:
    """Reproduce the source's ascending coefficient generator table."""
    generator = [0] * (PARITY_BYTES + 1)
    generator[0] = 2
    generator[1] = 1
    for root in range(2, PARITY_BYTES + 1):
        generator[root] = 1
        for index in range(root - 1, 0, -1):
            if generator[index] != 0:
                generator[index] = generator[index - 1] ^ alpha_to[(index_of[generator[index]] + root) % 255]
            else:
                generator[index] = generator[index - 1]
        generator[0] = alpha_to[(index_of[generator[0]] + root) % 255]
    return [index_of[value] for value in generator]


def _encode(payload: list[int], alpha_to: list[int], index_of: list[int], generator: list[int]) -> list[int]:
    data = [0] * 239
    data[51:] = payload
    parity = [0] * PARITY_BYTES
    for data_index in range(238, -1, -1):
        feedback = index_of[data[data_index] ^ parity[15]]
        if feedback != -1:
            for parity_index in range(15, 0, -1):
                if generator[parity_index] != -1:
                    parity[parity_index] = parity[parity_index - 1] ^ alpha_to[(generator[parity_index] + feedback) % 255]
                else:
                    parity[parity_index] = parity[parity_index - 1]
            parity[0] = alpha_to[(generator[0] + feedback) % 255]
        else:
            for parity_index in range(15, 0, -1):
                parity[parity_index] = parity[parity_index - 1]
            parity[0] = 0
    return payload + parity


def _gf_multiply(left: int, right: int) -> int:
    product = 0
    while right:
        if right & 1:
            product ^= left
        right >>= 1
        left <<= 1
        if left & 0x100:
            left ^= 0x11D
    return product


def _gf_divide(left: int, right: int, alpha_to: list[int], index_of: list[int]) -> int:
    if left == 0:
        return 0
    return alpha_to[(index_of[left] - index_of[right]) % 255]


def _correct_one_error(codeword: list[int], position: int, alpha_to: list[int], index_of: list[int]) -> bool:
    """Correct zero or one changed transmitted symbol using its two syndromes."""
    syndrome1 = 0
    syndrome2 = 0
    for full_position in range(255):
        if full_position < 16:
            symbol = codeword[188 + full_position]
        elif full_position < 67:
            symbol = 0
        else:
            symbol = codeword[full_position - 67]
        if symbol != 0:
            syndrome1 ^= _gf_multiply(symbol, alpha_to[full_position % 255])
            syndrome2 ^= _gf_multiply(symbol, alpha_to[(2 * full_position) % 255])
    if syndrome1 == 0 and syndrome2 == 0:
        return True
    if syndrome1 == 0:
        return False
    location = _gf_divide(syndrome2, syndrome1, alpha_to, index_of)
    full_position = next((i for i in range(255) if alpha_to[i] == location), -1)
    if full_position < 0:
        return False
    magnitude = _gf_divide(syndrome1, alpha_to[full_position], alpha_to, index_of)
    if full_position < 16:
        transmitted_position = 188 + full_position
    elif full_position >= 67:
        transmitted_position = full_position - 67
    else:
        return False
    if transmitted_position != position:
        return False
    codeword[transmitted_position] ^= magnitude
    return True


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if not isinstance(values, (list, tuple)) or len(values) < MESSAGE_BYTES + 1 or len(values) > MAX_INPUT_VALUES:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not 0 <= value <= 255 for value in values[:MESSAGE_BYTES]):
        return INVALID_RESULT, b""
    error_count = values[MESSAGE_BYTES]
    if type(error_count) is not int or error_count not in (0, 1):
        return INVALID_RESULT, b""
    if len(values) != MESSAGE_BYTES + 1 + 2 * error_count:
        return INVALID_RESULT, b""

    payload = list(values[:MESSAGE_BYTES])
    alpha_to, index_of = _field_tables()
    generator = _generator(alpha_to, index_of)
    codeword = _encode(payload, alpha_to, index_of, generator)
    if error_count == 1:
        position, replacement = values[-2:]
        if type(position) is not int or not 0 <= position < CODEWORD_BYTES:
            return INVALID_RESULT, b""
        if type(replacement) is not int or not 0 <= replacement <= 255:
            return INVALID_RESULT, b""
        codeword[position] = replacement
        if not _correct_one_error(codeword, position, alpha_to, index_of):
            return INVALID_RESULT, b""
    return CODEWORD_BYTES, bytes(codeword)

