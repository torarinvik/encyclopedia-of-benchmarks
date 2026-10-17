"""Reference oracle for the bounded Python RC4 encryption contract."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_KEY_LENGTH = 1
MAX_KEY_LENGTH = 256
MAX_PLAINTEXT_LENGTH = 256
MAX_VALID_INPUT_LENGTH = 2 + MAX_KEY_LENGTH + MAX_PLAINTEXT_LENGTH
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_PLAINTEXT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return the ciphertext bytes, or an ABI error and an empty byte string."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    key_length, plaintext_length = values[0], values[1]
    if not MIN_KEY_LENGTH <= key_length <= MAX_KEY_LENGTH:
        return INVALID_RESULT, b""
    if not 0 <= plaintext_length <= MAX_PLAINTEXT_LENGTH:
        return INVALID_RESULT, b""
    if len(values) != 2 + key_length + plaintext_length:
        return INVALID_RESULT, b""

    key = values[2 : 2 + key_length]
    plaintext = values[2 + key_length :]
    if any(byte < 0 or byte > 255 for byte in key + plaintext):
        return INVALID_RESULT, b""

    if plaintext_length == 0:
        return 0, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < plaintext_length:
        return OUTPUT_ERROR, b""

    state = list(range(256))
    j = 0
    for i in range(256):
        j = (j + state[i] + key[i % key_length]) & 0xFF
        state[i], state[j] = state[j], state[i]

    i = 0
    j = 0
    ciphertext = bytearray(plaintext_length)
    for offset, byte in enumerate(plaintext):
        i = (i + 1) & 0xFF
        j = (j + state[i]) & 0xFF
        state[i], state[j] = state[j], state[i]
        stream_byte = state[(state[i] + state[j]) & 0xFF]
        ciphertext[offset] = byte ^ stream_byte
    return plaintext_length, bytes(ciphertext)
