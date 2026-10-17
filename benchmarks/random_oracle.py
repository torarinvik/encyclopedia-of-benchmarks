"""Oracle for the bounded pinned Rust PCG32 generator."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_COUNT = 256
MAX_VALID_INPUT_LENGTH = 4
MAX_PARSEABLE_INPUT_LENGTH = 5
MAX_OUTPUT_BYTES = MAX_COUNT * 4
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
U64_MASK = (1 << 64) - 1
U32_MASK = (1 << 32) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return generated PCG32 values as little-endian unsigned-i32 bytes."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT, b""

    seed_bits, multiplier_bits, stream, count = values
    if not 0 <= stream <= I64_MAX or not 0 <= count <= MAX_COUNT:
        return INVALID_RESULT, b""

    seed = seed_bits & U64_MASK
    multiplier = multiplier_bits & U64_MASK
    increment = ((stream << 1) | 1) & U64_MASK
    state = (seed + increment) & U64_MASK
    state = (state * multiplier + increment) & U64_MASK

    generated: list[int] = []
    for _ in range(count):
        value = state
        rotation = value >> 59
        state = (state * multiplier + increment) & U64_MASK
        value ^= value >> 18
        output = (value >> 27) & U32_MASK
        rotation &= 31
        output = ((output >> rotation) | (output << ((-rotation) & 31))) & U32_MASK
        generated.append(output)

    encoded = struct.pack("<" + "I" * len(generated), *generated)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
