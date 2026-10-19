"""Bounded reference for Trimaran's fixed three-key DES EDE block stage."""
from __future__ import annotations

from des_ecb_oracle import _encrypt_block, _subkeys

MAX_INPUT_LENGTH = 9
OUTPUT_BYTES = 8
INVALID_RESULT = -1
KEYS = (0x0123456789ABCDEF, 0x23456789ABCDEF01, 0x456789ABCDEF0123)

def _apply(block: int, key: int, decrypt: bool) -> int:
    subkeys = _subkeys(key)
    return _encrypt_block(block, tuple(reversed(subkeys)) if decrypt else subkeys)

def expected_output(values: tuple[int, ...] | list[int], output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or len(values) != MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return INVALID_RESULT, b""
    direction, *raw = values
    if direction not in (0, 1) or any(not 0 <= x <= 255 for x in raw):
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if output_capacity is not None and output_capacity < OUTPUT_BYTES:
        return -2, b""
    block = int.from_bytes(bytes(raw), "big")
    k1, k2, k3 = KEYS
    if direction == 0:
        result = _apply(_apply(_apply(block, k1, False), k2, True), k3, False)
    else:
        result = _apply(_apply(_apply(block, k3, True), k2, False), k1, True)
    return OUTPUT_BYTES, result.to_bytes(OUTPUT_BYTES, "big")
