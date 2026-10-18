"""Oracle for the bounded Ruby byte/chunk RSA contract."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MODULUS = 33
MIN_EXPONENT = 1
MAX_EXPONENT = 7
MAX_MESSAGE_LENGTH = 64
MAX_VALID_INPUT_LENGTH = 4 + MAX_MESSAGE_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
CHUNK_WIDTH = len(str(MODULUS))

FNV_OFFSET_BASIS = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = 0xFFFFFFFFFFFFFFFF
MASK63 = 0x7FFFFFFFFFFFFFFF
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _hash_bytes(hash_value: int, data: bytes) -> int:
    for byte in data:
        hash_value = ((hash_value ^ byte) * FNV_PRIME) & MASK64
    return hash_value


def expected_result(input_values: Sequence[int] | None) -> int:
    """Return the decimal-chunk round-trip fingerprint, or -1 if invalid."""
    if input_values is None or not isinstance(input_values, Sequence):
        return INVALID_RESULT
    values = list(input_values)
    if len(values) < 4 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    modulus, public_exponent, private_exponent, message_length = values[:4]
    if modulus != MODULUS:
        return INVALID_RESULT
    if not MIN_EXPONENT <= public_exponent <= MAX_EXPONENT:
        return INVALID_RESULT
    if not MIN_EXPONENT <= private_exponent <= MAX_EXPONENT:
        return INVALID_RESULT
    if not 1 <= message_length <= MAX_MESSAGE_LENGTH or len(values) != 4 + message_length:
        return INVALID_RESULT

    message = values[4:]
    if any(not 0 <= value < MODULUS for value in message):
        return INVALID_RESULT

    ciphertexts = [pow(value, public_exponent, modulus) for value in message]
    ciphertext_text = "".join(f"{value:0{CHUNK_WIDTH}d}" for value in ciphertexts)
    recovered = [
        pow(int(ciphertext_text[offset : offset + CHUNK_WIDTH]), private_exponent, modulus)
        for offset in range(0, len(ciphertext_text), CHUNK_WIDTH)
    ]

    fingerprint = _hash_bytes(FNV_OFFSET_BASIS, ciphertext_text.encode("ascii"))
    fingerprint = _hash_bytes(fingerprint, bytes(recovered))
    return fingerprint & MASK63
