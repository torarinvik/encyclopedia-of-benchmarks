"""ChaCha20 block-function oracle for sixteen little-endian 32-bit words."""

from __future__ import annotations

import struct

WORD_MASK = 0xFFFF_FFFF
WORD_COUNT = 16
OUTPUT_BYTES = WORD_COUNT * 4


def _quarter_round(state: list[int], a: int, b: int, c: int, d: int) -> None:
    state[a] = (state[a] + state[b]) & WORD_MASK
    mixed = state[d] ^ state[a]
    state[d] = ((mixed << 16) | (mixed >> 16)) & WORD_MASK
    state[c] = (state[c] + state[d]) & WORD_MASK
    mixed = state[b] ^ state[c]
    state[b] = ((mixed << 12) | (mixed >> 20)) & WORD_MASK
    state[a] = (state[a] + state[b]) & WORD_MASK
    mixed = state[d] ^ state[a]
    state[d] = ((mixed << 8) | (mixed >> 24)) & WORD_MASK
    state[c] = (state[c] + state[d]) & WORD_MASK
    mixed = state[b] ^ state[c]
    state[b] = ((mixed << 7) | (mixed >> 25)) & WORD_MASK


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) != WORD_COUNT
            or any(type(value) is not int or not 0 <= value <= WORD_MASK for value in values)):
        return -1, b""

    initial = list(values)
    state = initial.copy()
    for _ in range(10):
        _quarter_round(state, 0, 4, 8, 12)
        _quarter_round(state, 1, 5, 9, 13)
        _quarter_round(state, 2, 6, 10, 14)
        _quarter_round(state, 3, 7, 11, 15)
        _quarter_round(state, 0, 5, 10, 15)
        _quarter_round(state, 1, 6, 11, 12)
        _quarter_round(state, 2, 7, 8, 13)
        _quarter_round(state, 3, 4, 9, 14)
    state = [(word + original) & WORD_MASK for word, original in zip(state, initial)]
    return OUTPUT_BYTES, struct.pack("<16I", *state)
