"""Integer based oracle for the bounded Bitcoin Base58Check profile."""

from __future__ import annotations

import hashlib
from collections.abc import Sequence

MAX_PAYLOAD = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_PAYLOAD
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 51
WORKSPACE_BYTES = 826
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
ALPHABET = b"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def _encode(raw: bytes) -> bytes:
    zeroes = len(raw) - len(raw.lstrip(b"\x00"))
    number = int.from_bytes(raw, "big")
    digits = bytearray()
    while number:
        number, remainder = divmod(number, 58)
        digits.append(ALPHABET[remainder])
    return b"1" * zeroes + bytes(reversed(digits))


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
    version, payload_length = values[:2]
    if (not 0 <= version <= 255 or not 0 <= payload_length <= MAX_PAYLOAD
            or len(values) != 2 + payload_length
            or any(not 0 <= byte <= 255 for byte in values[2:])):
        return None
    return bytes((version, *values[2:]))


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return status and output bytes without mutating a caller buffer."""
    if (type(output_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    message = _parse(values, input_is_null, input_length)
    if message is None:
        return -1, b""
    first = hashlib.sha256(message).digest()
    checksum = hashlib.sha256(first).digest()[:4]
    encoded = _encode(message + checksum)
    if output_is_null or capacity is not None and capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
