"""Independent state-machine oracle for the bounded VersaBench 8b10b profile."""

from __future__ import annotations

from typing import Sequence

MAX_WORDS = 160
MAX_PARSEABLE_WORDS = MAX_WORDS + 1
MAX_OUTPUT_BYTES = 18
INVALID_RESULT = -1
OUTPUT_ERROR = -2

# The low bits hold the source's selected code bits. Metadata is stored in
# bits 10 (FLIP), 11 (PLUS), and 12 (X), following calc.c's table flags.
RAW5 = (
    0x0D80, 0x05A2, 0x0C60, 0x0CC0, 0x0CA0, 0x10A2, 0x10C2, 0x10E0,
    0x0D20, 0x1122, 0x1142, 0x1160, 0x1182, 0x11A0, 0x11C0, 0x05E0,
    0x0E20, 0x1222, 0x1242, 0x1260, 0x1282, 0x12A0, 0x12C0, 0x06E0,
    0x1302, 0x1320, 0x1340, 0x0760, 0x0380, 0x07A0, 0x0E80, 0x06A2,
)
RAW3 = (0x0C08, 0x0C04, 0x1009, 0x100C, 0x1011, 0x1014, 0x0018, 0x041C)


def _calc(packed_word: int, disparity: int) -> tuple[int, int]:
    """Apply one direct calc() call and return its codeword and next disparity."""
    data = packed_word & 0xFF
    k = packed_word >> 8
    index5 = data >> 3
    index3 = data & 7

    lookup5 = RAW5[index5]
    if k == 1 and index5 == 7:
        lookup5 = 0x04E2
    lookup3 = RAW3[index3]
    if k == 1:
        if 2 <= index3 <= 5:
            lookup3 = (lookup3 & ~0x1000) | 0x0800
        elif index3 == 7:
            lookup3 = 0x040D

    if lookup5 & 0x1000:
        result = lookup5 & 0x03E2
        disparity1 = disparity
    else:
        code5 = lookup5 & 0x03E2
        result = code5 if disparity == int(bool(lookup5 & 0x0800)) else code5 ^ 0x03E2
        disparity1 = disparity ^ int(bool(lookup5 & 0x0400))

    if lookup3 & 0x1000:
        result |= lookup3 & 0x001D
        next_disparity = disparity1
    else:
        code3 = lookup3 & 0x001D
        result |= code3 if disparity1 == int(bool(lookup3 & 0x0800)) else code3 ^ 0x001D
        next_disparity = disparity1 ^ int(bool(lookup3 & 0x0400))
    return result, next_disparity


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the bounded launcher's sampled `%8.8X\n` stdout bytes."""
    if (
        not isinstance(values, (tuple, list))
        or len(values) > MAX_PARSEABLE_WORDS
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
        or type(input_is_null) is not bool
        or type(output_is_null) is not bool
        or (input_is_null and (values or input_length != 0))
        or (input_length is not None
            and (type(input_length) is not int or input_length != len(values)))
    ):
        return INVALID_RESULT, b""
    if len(values) > MAX_WORDS or any(not 0 <= value <= 0x1FF for value in values):
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0 or type(output_is_null) is not bool:
        return INVALID_RESULT, b""

    word_count = len(values)
    sample_count = 0 if word_count == 0 else (word_count - 1) // 128 + 1
    required = sample_count * 9
    if required and (output_is_null or output_capacity < required):
        return OUTPUT_ERROR, b""

    disparity = 0
    sampled: list[int] = []
    for pass_index in range(word_count):
        for index, packed_word in enumerate(values):
            encoded, disparity = _calc(packed_word, disparity)
            if pass_index == word_count - 1 and index % 128 == 0:
                sampled.append(encoded)

    output = b"".join(f"{encoded:08X}\n".encode("ascii") for encoded in sampled)
    return len(output), output
