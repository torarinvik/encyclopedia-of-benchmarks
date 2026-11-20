"""RFC 6238 SHA-1 TOTP oracle for a small byte-output ABI profile."""

from __future__ import annotations

import hashlib
import hmac
from collections.abc import Sequence

MAX_KEY_BYTES = 64
MAX_VALID_INPUT_LENGTH = 66
MAX_PARSEABLE_INPUT_LENGTH = 67
MAX_OUTPUT_BYTES = 6
WORKSPACE_BYTES = 1024
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[bytes, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    key_length = values[0]
    if not 16 <= key_length <= MAX_KEY_BYTES or len(values) != key_length + 2:
        return None
    key_values = values[1:key_length + 1]
    timestamp = values[key_length + 1]
    if any(not 0 <= byte <= 255 for byte in key_values) or not 0 <= timestamp <= _I64_MAX:
        return None
    return bytes(key_values), timestamp


def _totp(key: bytes, timestamp: int) -> bytes:
    counter = timestamp // 30
    digest = hmac.new(key, counter.to_bytes(8, "big"), hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    binary = int.from_bytes(digest[offset:offset + 4], "big") & 0x7FFFFFFF
    value = binary % 1_000_000
    digits = bytearray(6)
    for index in range(5, -1, -1):
        digits[index] = 48 + value % 10
        value //= 10
    return bytes(digits)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    payload = _totp(*parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
