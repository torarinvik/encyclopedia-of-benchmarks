"""Independent bounded oracle for the Pukall Cipher 1 Trimaran profile."""

from __future__ import annotations

MAX_NUM_INPUT = 2049
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1
DEFAULT_KEY = bytearray(b"abcdefghijklmnopqrstuvwxyz012345")
MASK16 = 0xFFFF
MASK32 = 0xFFFFFFFF


def _code_step(words: list[int], state: list[int], index: int) -> int:
    """Advance one 16-bit state word using the published PC1 recurrence."""
    si, x1a2 = state
    dx = (x1a2 + index) & MASK16
    ax = words[index]
    cx = 0x015A
    bx = 0x4E35

    tmp = ax
    ax, si = si, tmp
    tmp = ax
    ax, dx = dx, tmp
    if ax != 0:
        ax = (ax * bx) & MASK16
    tmp = ax
    ax, cx = cx, tmp
    if ax != 0:
        ax = (ax * si) & MASK16
        cx = (ax + cx) & MASK16
    tmp = ax
    ax, si = si, tmp
    ax = (ax * bx) & MASK16
    dx = (cx + dx) & MASK16
    ax = (ax + 1) & MASK16

    state[0] = si
    state[1] = dx
    words[index] = ax
    return ax ^ dx


def _assemble(words: list[int], state: list[int], key: bytearray) -> int:
    words[0] = (key[0] << 8) | key[1]
    inter = _code_step(words, state, 0)
    for index in range(1, 16):
        key_word = (key[2 * index] << 8) | key[2 * index + 1]
        words[index] = words[index - 1] ^ key_word
        inter ^= _code_step(words, state, index)
    return inter & MASK16


def expected_result(values: list[int]) -> int:
    """Return the last source ciphertext word for a bounded NumInput value.

    The C launcher loop is ``while (--NumInput)``; therefore ``values[0]``
    encodes one more than the number of processed pseudo-random input bytes.
    """
    if len(values) != 1 or not 1 <= values[0] <= MAX_NUM_INPUT:
        return INVALID_RESULT

    key = bytearray(DEFAULT_KEY)
    words = [0] * 16
    state = [0, 0]  # si, x1a2; the C source relies on zero-initialized globals.
    seed = 1
    last_cipher = 0

    for _ in range(values[0] - 1):
        seed = (seed * 1664525 + 1013904223) & MASK32
        plain = (seed >> 16) & 0x7FFF
        inter = _assemble(words, state, key)
        feedback = plain & 0xFF
        for index in range(32):
            key[index] ^= feedback
        last_cipher = (plain ^ ((inter >> 8) ^ (inter & 0xFF))) & MASK16

    return last_cipher
