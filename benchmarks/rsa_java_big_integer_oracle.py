"""Oracle for the bounded Java BigInteger RSA overload contract."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MIN_MODULUS = 128
MAX_MODULUS = 55_295
MIN_EXPONENT = 1
MAX_EXPONENT = 1_000_000
MAX_MESSAGE_LENGTH = 64
MAX_VALID_INPUT_LENGTH = 4 + MAX_MESSAGE_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1

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
    """Return the BigInteger transform fingerprint, or -1 for invalid input."""
    if input_values is None or not isinstance(input_values, Sequence):
        return INVALID_RESULT
    values = list(input_values)
    if len(values) < 4 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    modulus, public_exponent, private_exponent, message_length = values[:4]
    if not MIN_MODULUS <= modulus <= MAX_MODULUS:
        return INVALID_RESULT
    if not MIN_EXPONENT <= public_exponent <= MAX_EXPONENT:
        return INVALID_RESULT
    if not MIN_EXPONENT <= private_exponent <= MAX_EXPONENT:
        return INVALID_RESULT
    if not 1 <= message_length <= MAX_MESSAGE_LENGTH or len(values) != 4 + message_length:
        return INVALID_RESULT

    messages = values[4:]
    if any(not 0 <= value <= 127 or value >= modulus for value in messages):
        return INVALID_RESULT

    ciphertexts = [pow(value, public_exponent, modulus) for value in messages]
    recovered = [pow(value, private_exponent, modulus) for value in ciphertexts]

    fingerprint = FNV_OFFSET_BASIS
    for value in ciphertexts:
        fingerprint = _hash_bytes(fingerprint, value.to_bytes(4, "little", signed=False))
    for value in recovered:
        fingerprint = _hash_bytes(fingerprint, value.to_bytes(4, "little", signed=False))
    return fingerprint & MASK63
