"""Independent byte-oriented model for the bounded Blowfish CBC profile."""
from __future__ import annotations

from collections.abc import Sequence

from mibench_security_blowfish_oracle import KEYS, _block

MIN_BLOCKS = 1
MAX_BLOCKS = 4
MAX_INPUT_LENGTH = 11 + 8 * MAX_BLOCKS
MAX_OUTPUT_BYTES = 8 * MAX_BLOCKS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or type(output_is_null) is not bool):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return INVALID_RESULT, b""
    if len(values) < 19 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(value < 0 or value > 255 for value in values):
        return INVALID_RESULT, b""

    direction, key_id, block_count = values[:3]
    if (direction not in (0, 1) or key_id not in (0, 1)
            or not MIN_BLOCKS <= block_count <= MAX_BLOCKS
            or len(values) != 11 + 8 * block_count):
        return INVALID_RESULT, b""
    iv = bytes(values[3:11])
    data = bytes(values[11:])
    chain = iv
    result = bytearray()
    key = KEYS[key_id]
    for offset in range(0, len(data), 8):
        block = data[offset:offset + 8]
        if direction == 0:
            encrypted = _block(key, bytes(a ^ b for a, b in zip(block, chain)), False)
            result.extend(encrypted)
            chain = encrypted
        else:
            plain = _block(key, block, True)
            result.extend(a ^ b for a, b in zip(plain, chain))
            chain = block

    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(result)
    ):
        return OUTPUT_ERROR, b""
    return len(result), bytes(result)
