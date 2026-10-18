"""Independent oracle for the bounded Java Lamport signature contract."""

from __future__ import annotations

import hashlib
import hmac
from collections.abc import Sequence

INVALID_RESULT = -1
MAX_MESSAGE_BYTES = 64
DIGEST_BITS = 256
SECRET_BYTES = 32
ENTROPY_BYTES = DIGEST_BITS * 2 * SECRET_BYTES
SIGNATURE_BYTES = DIGEST_BITS * SECRET_BYTES
MAX_VALID_INPUT_LENGTH = 4 + 2 * MAX_MESSAGE_BYTES + ENTROPY_BYTES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1

FNV_OFFSET_BASIS = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = 0xFFFFFFFFFFFFFFFF
MASK63 = 0x7FFFFFFFFFFFFFFF


def _is_i64(value: object) -> bool:
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def expected_result(input_values: Sequence[int] | None) -> int:
    """Return the low-63 FNV fingerprint or -1 for malformed input.

    The input frame is [message_len, message..., verify_message_len,
    verify_message..., tamper_index, sign_twice, 16384 supplied entropy bytes].
    Entropy is split into 512 consecutive 32-byte blocks in source order:
    bit position 0/value 0, bit position 0/value 1, then bit position 1, etc.
    """
    if input_values is None or not isinstance(input_values, Sequence):
        return INVALID_RESULT
    values = list(input_values)
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(not _is_i64(value) for value in values):
        return INVALID_RESULT
    if not values:
        return INVALID_RESULT

    message_length = values[0]
    if not 0 <= message_length <= MAX_MESSAGE_BYTES:
        return INVALID_RESULT
    message_start = 1
    message_end = message_start + message_length
    if len(values) < message_end + 1:
        return INVALID_RESULT
    message = values[message_start:message_end]

    verify_length = values[message_end]
    if not 0 <= verify_length <= MAX_MESSAGE_BYTES:
        return INVALID_RESULT
    verify_start = message_end + 1
    verify_end = verify_start + verify_length
    if len(values) < verify_end + 2:
        return INVALID_RESULT
    verify_message = values[verify_start:verify_end]
    tamper_index = values[verify_end]
    sign_twice = values[verify_end + 1]
    entropy_start = verify_end + 2

    if not -1 <= tamper_index < SIGNATURE_BYTES or sign_twice not in (0, 1):
        return INVALID_RESULT
    if len(values) != entropy_start + ENTROPY_BYTES:
        return INVALID_RESULT
    if any(not 0 <= value <= 255 for value in message + verify_message):
        return INVALID_RESULT
    entropy_values = values[entropy_start:]
    if any(not 0 <= value <= 255 for value in entropy_values):
        return INVALID_RESULT

    entropy = bytes(entropy_values)
    private_key: list[list[bytes]] = []
    public_key: list[list[bytes]] = []
    cursor = 0
    for _bit in range(DIGEST_BITS):
        private_pair: list[bytes] = []
        public_pair: list[bytes] = []
        for _value in range(2):
            secret = entropy[cursor : cursor + SECRET_BYTES]
            cursor += SECRET_BYTES
            private_pair.append(secret)
            public_pair.append(hashlib.sha256(secret).digest())
        private_key.append(private_pair)
        public_key.append(public_pair)

    message_digest = hashlib.sha256(bytes(message)).digest()
    signature_parts = []
    for bit in range(DIGEST_BITS):
        value = (message_digest[bit // 8] >> (7 - (bit % 8))) & 1
        signature_parts.append(private_key[bit][value])
    signature = b"".join(signature_parts)

    # Model the source order: key generation and the first sign complete
    # before a second sign attempt triggers KeyPair's one-time-use exception.
    if sign_twice == 1:
        return INVALID_RESULT

    verification_signature = bytearray(signature)
    if tamper_index >= 0:
        verification_signature[tamper_index] ^= 1
    verify_digest = hashlib.sha256(bytes(verify_message)).digest()
    verified = True
    for bit in range(DIGEST_BITS):
        value = (verify_digest[bit // 8] >> (7 - (bit % 8))) & 1
        revealed = verification_signature[bit * SECRET_BYTES : (bit + 1) * SECRET_BYTES]
        actual_hash = hashlib.sha256(revealed).digest()
        if not hmac.compare_digest(actual_hash, public_key[bit][value]):
            verified = False
            break

    fingerprint = FNV_OFFSET_BASIS
    for byte in b"".join(b"".join(pair) for pair in public_key) + signature + bytes([int(verified)]):
        fingerprint ^= byte
        fingerprint = (fingerprint * FNV_PRIME) & MASK64
    return fingerprint & MASK63
