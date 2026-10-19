"""Independent fixed-block IDEA encryption/decryption oracle."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_VALID_INPUT_LENGTH = 12
MAX_PARSEABLE_INPUT_LENGTH = 12
MAX_OUTPUT_BYTES = 16
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _multiply(left: int, right: int) -> int:
    a = 65536 if left == 0 else left
    b = 65536 if right == 0 else right
    residue = (a * b) % 65537
    return 0 if residue == 65536 else residue


def _inverse(value: int) -> int:
    # Extended Euclid in the multiplicative group modulo 65537.
    a = 65536 if value == 0 else value
    old_r, r, old_s, s = 65537, a, 0, 1
    while r:
        quotient = old_r // r
        old_r, r = r, old_r - quotient * r
        old_s, s = s, old_s - quotient * s
    return old_s % 65537 % 65536


def _expand_key(key: Sequence[int]) -> list[int]:
    words = list(key)
    expanded: list[int] = []
    while len(expanded) < 52:
        expanded.extend(words[: min(8, 52 - len(expanded))])
        words = [((words[(i + 1) & 7] << 9) | (words[(i + 2) & 7] >> 7)) & 0xFFFF
                 for i in range(8)]
    return expanded


def _encrypt(key: Sequence[int], block: Sequence[int]) -> list[int]:
    x1, x2, x3, x4 = block
    for round_index in range(8):
        offset = round_index * 6
        k1, k2, k3, k4, k5, k6 = key[offset:offset + 6]
        a, b, c, d = _multiply(x1, k1), (x2 + k2) & 0xFFFF, (x3 + k3) & 0xFFFF, _multiply(x4, k4)
        p = _multiply(a ^ c, k5)
        q = _multiply(((b ^ d) + p) & 0xFFFF, k6)
        r = (p + q) & 0xFFFF
        x1, x2, x3, x4 = a ^ q, c ^ q, b ^ r, d ^ r
    return [_multiply(x1, key[48]), (x3 + key[49]) & 0xFFFF,
            (x2 + key[50]) & 0xFFFF, _multiply(x4, key[51])]


def _decrypt(key: Sequence[int], cipher: Sequence[int]) -> list[int]:
    x1 = _multiply(cipher[0], _inverse(key[48]))
    x2 = (cipher[2] - key[50]) & 0xFFFF
    x3 = (cipher[1] - key[49]) & 0xFFFF
    x4 = _multiply(cipher[3], _inverse(key[51]))
    for round_index in range(7, -1, -1):
        offset = round_index * 6
        k1, k2, k3, k4, k5, k6 = key[offset:offset + 6]
        p = _multiply(x1 ^ x2, k5)
        q = _multiply(((x3 ^ x4) + p) & 0xFFFF, k6)
        r = (p + q) & 0xFFFF
        a, c, b, d = x1 ^ q, x2 ^ q, x3 ^ r, x4 ^ r
        x1, x2, x3, x4 = _multiply(a, _inverse(k1)), (b - k2) & 0xFFFF, (c - k3) & 0xFFFF, _multiply(d, _inverse(k4))
    return [x1, x2, x3, x4]


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and 16-byte result for `[K0..K7, P0..P3]`."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (list, tuple))
            or (input_length is not None and input_length != len(values))
            or len(values) != 12
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    if any(value < 0 or value > 65535 for value in values):
        return INVALID_RESULT, b""
    subkeys = _expand_key(values[:8])
    cipher = _encrypt(subkeys, values[8:])
    recovered = _decrypt(subkeys, cipher)
    result = struct.pack("<8H", *(cipher + recovered))
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return OUTPUT_ERROR, b""
    return len(result), result
