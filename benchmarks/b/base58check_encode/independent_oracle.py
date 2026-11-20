"""Byte-array division reference for bounded Bitcoin Base58Check encoding."""

from __future__ import annotations

import hashlib
from collections.abc import Sequence

MAX_PAYLOAD = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_PAYLOAD
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
ALPHABET = b"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def _encode_by_division(raw: bytes) -> bytes:
    zeroes = 0
    while zeroes < len(raw) and raw[zeroes] == 0:
        zeroes += 1
    work = list(raw[zeroes:])
    reversed_digits = bytearray()
    while work:
        quotient: list[int] = []
        remainder = 0
        for octet in work:
            value = remainder * 256 + octet
            digit, remainder = divmod(value, 58)
            if quotient or digit:
                quotient.append(digit)
        reversed_digits.append(ALPHABET[remainder])
        work = quotient
    return b"1" * zeroes + bytes(reversed(reversed_digits))


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> bytes | None:
    if (type(input_is_null) is not bool or input_is_null
            or values is None or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if (input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    version, count = values[0], values[1]
    if (version < 0 or version > 255 or count < 0 or count > MAX_PAYLOAD
            or len(values) != count + 2):
        return None
    payload = bytearray()
    for value in values[2:]:
        if value < 0 or value > 255:
            return None
        payload.append(value)
    return bytes((version,)) + payload


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return status and output bytes using repeated byte-array division."""
    if (type(output_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    message = _parse(values, input_is_null, input_length)
    if message is None:
        return -1, b""
    digest_one = hashlib.sha256(message).digest()
    digest_two = hashlib.sha256(digest_one).digest()
    raw = message + digest_two[:4]
    encoded = _encode_by_division(raw)
    if output_is_null or capacity is not None and capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
