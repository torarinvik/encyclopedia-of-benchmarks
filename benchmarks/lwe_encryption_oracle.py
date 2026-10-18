"""Oracle for the pinned Java LWE encrypt/decrypt contract."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
DIMENSION = 32
MODULUS = 3329
SAMPLES = 128
ERROR_BOUND = 3
MAX_MESSAGE_BYTES = 4
BITS_PER_BYTE = 8
SUBSET_BITS_PER_MESSAGE_BIT = SAMPLES
MAX_SUBSET_BITS = MAX_MESSAGE_BYTES * BITS_PER_BYTE * SAMPLES
MAX_VALID_INPUT_LENGTH = 1 + MAX_MESSAGE_BYTES + DIMENSION + SAMPLES * DIMENSION + SAMPLES + MAX_SUBSET_BITS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1

FNV_OFFSET_BASIS = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = 0xFFFFFFFFFFFFFFFF
MASK63 = 0x7FFFFFFFFFFFFFFF
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _hash_byte(hash_value: int, byte: int) -> int:
    return ((hash_value ^ byte) * FNV_PRIME) & MASK64


def expected_result(input_values: Sequence[int] | None) -> int:
    """Return a ciphertext/decryption fingerprint, or -1 for malformed input.

    The packed frame is [message_length, message_bytes..., s[32], A[128*32],
    error_draws[128], subset_bits...]. `A` is row-major. Error values are the
    raw nextInt(7) results (0 through 6), before the source subtracts 3. There
    are 128 boolean subset values for every message bit, in message-bit order.
    """
    if input_values is None or not isinstance(input_values, Sequence):
        return INVALID_RESULT
    values = list(input_values)
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    if not values:
        return INVALID_RESULT

    message_length = values[0]
    if not 1 <= message_length <= MAX_MESSAGE_BYTES:
        return INVALID_RESULT
    expected_length = 1 + message_length + DIMENSION + SAMPLES * DIMENSION + SAMPLES + message_length * BITS_PER_BYTE * SAMPLES
    if len(values) != expected_length:
        return INVALID_RESULT

    message_start = 1
    message_end = message_start + message_length
    message = values[message_start:message_end]
    if any(not 0 <= byte <= 255 for byte in message):
        return INVALID_RESULT

    secret_start = message_end
    secret_end = secret_start + DIMENSION
    secret = values[secret_start:secret_end]
    if any(not 0 <= value < MODULUS for value in secret):
        return INVALID_RESULT

    matrix_start = secret_end
    matrix_end = matrix_start + SAMPLES * DIMENSION
    matrix = values[matrix_start:matrix_end]
    if any(not 0 <= value < MODULUS for value in matrix):
        return INVALID_RESULT

    error_start = matrix_end
    error_end = error_start + SAMPLES
    error_draws = values[error_start:error_end]
    if any(not 0 <= value <= 2 * ERROR_BOUND for value in error_draws):
        return INVALID_RESULT
    subset_bits = values[error_end:]
    if len(subset_bits) != message_length * BITS_PER_BYTE * SAMPLES or any(bit not in (0, 1) for bit in subset_bits):
        return INVALID_RESULT

    public_b: list[int] = []
    for row in range(SAMPLES):
        total = 0
        row_start = row * DIMENSION
        for column in range(DIMENSION):
            total += matrix[row_start + column] * secret[column]
        error = error_draws[row] - ERROR_BOUND
        public_b.append((total + error) % MODULUS)

    ciphertext_words: list[int] = []
    decrypted_message = bytearray()
    subset_cursor = 0
    for message_byte in message:
        decoded_byte = 0
        for bit_index in range(BITS_PER_BYTE):
            message_bit = (message_byte >> (7 - bit_index)) & 1
            u_accumulator = [0] * DIMENSION
            v_accumulator = message_bit * (MODULUS // 2)
            for row in range(SAMPLES):
                selected = subset_bits[subset_cursor]
                subset_cursor += 1
                if selected:
                    row_start = row * DIMENSION
                    for column in range(DIMENSION):
                        u_accumulator[column] += matrix[row_start + column]
                    v_accumulator += public_b[row]

            u = [value % MODULUS for value in u_accumulator]
            v = v_accumulator % MODULUS
            ciphertext_words.extend(u)
            ciphertext_words.append(v)

            dot = sum(u[column] * secret[column] for column in range(DIMENSION))
            difference = (v - dot) % MODULUS
            decrypted_bit = int(MODULUS // 4 <= difference < (3 * MODULUS) // 4)
            decoded_byte = (decoded_byte << 1) | decrypted_bit
        decrypted_message.append(decoded_byte)

    fingerprint = FNV_OFFSET_BASIS
    for word in ciphertext_words:
        fingerprint = _hash_byte(fingerprint, word & 0xFF)
        fingerprint = _hash_byte(fingerprint, (word >> 8) & 0xFF)
    for byte in decrypted_message:
        fingerprint = _hash_byte(fingerprint, byte)
    return fingerprint & MASK63
