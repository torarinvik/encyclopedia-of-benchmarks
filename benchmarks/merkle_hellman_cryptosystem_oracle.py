"""Deterministic one-byte oracle for TheAlgorithms/Ruby Merkle-Hellman."""

from __future__ import annotations

import math
import struct

WORD_MAX = (1 << 32) - 1
BASE_WEIGHT = 1 << 32
WEIGHT_COUNT = 8
MAX_DRAWS = 32
MAX_INPUT_LENGTH = 11 + MAX_DRAWS
OUTPUT_BYTES = 17
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
) -> tuple[int, bytes]:
    """Return ciphertext and the source-decrypted byte, or an ABI status."""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if (
        len(values) < 12
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    message_byte = values[0]
    if not 0 <= message_byte <= 127:
        return INVALID_RESULT, b""
    weight_draws = values[1:9]
    modulus_draw = values[9]
    draw_count = values[10]
    if any(not 0 <= draw <= WORD_MAX for draw in weight_draws):
        return INVALID_RESULT, b""
    if not 0 <= modulus_draw <= WORD_MAX:
        return INVALID_RESULT, b""
    if not 1 <= draw_count <= MAX_DRAWS or len(values) != 11 + draw_count:
        return INVALID_RESULT, b""

    easy_knapsack: list[int] = []
    total = BASE_WEIGHT
    for draw in weight_draws:
        weight = total + draw
        easy_knapsack.append(weight)
        total += weight
    modulus = total + modulus_draw

    a_draws = values[11:]
    for draw in a_draws:
        if not 0 <= draw <= modulus:
            return INVALID_RESULT, b""
    if any(math.gcd(draw, modulus) == 1 for draw in a_draws[:-1]):
        return INVALID_RESULT, b""
    multiplier = a_draws[-1]
    if math.gcd(multiplier, modulus) != 1:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""

    public_knapsack = [(multiplier * weight) % modulus for weight in easy_knapsack]
    ciphertext = 0
    for bit_index in range(7, -1, -1):
        if (message_byte >> bit_index) & 1:
            ciphertext += public_knapsack[7 - bit_index]

    residue = (pow(multiplier, -1, modulus) * (ciphertext % modulus)) % modulus
    decoded_byte = 0
    for index, weight in enumerate(reversed(easy_knapsack)):
        bit = 0
        if residue >= weight:
            residue -= weight
            bit = 1
        decoded_byte |= bit << index

    output = struct.pack("<qqB", ciphertext, 1, decoded_byte)
    if output_capacity is not None and output_capacity < len(output):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
