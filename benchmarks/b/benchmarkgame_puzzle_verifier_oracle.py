"""Reference puzzle outputs via XOR invariance and affine RNG jumps."""

import struct

_MASK = (1 << 64) - 1
_MULTIPLIER = 1_103_515_245
_INCREMENT = 12_345


def _advance(state, count):
    """Exponentiate the affine transition, modulo 2**64."""
    scale, offset = 1, 0
    factor, shift = _MULTIPLIER, _INCREMENT
    while count:
        if count & 1:
            scale, offset = (factor * scale) & _MASK, (factor * offset + shift) & _MASK
        factor, shift = (factor * factor) & _MASK, (factor * shift + shift) & _MASK
        count >>= 1
    return (scale * state + offset) & _MASK


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 3
            or any(type(value) is not int for value in values)):
        return -1, b""
    size, rounds, scans = values
    if not 1 <= size <= 100_000 or not 1 <= rounds <= 8 or not 1 <= scans <= 64:
        return -1, b""
    state = 1
    results = []
    for _ in range(rounds):
        state = _advance(state, 1)
        draw = ((state >> 16) & 0xFFFFFFFF) % 32767 + 1
        results.append(1 + size * draw // 32768)
        # Shuffling consumes one random value for each of size swaps. XOR is
        # permutation invariant, so no shuffled array is needed here.
        state = _advance(state, size)
    return 4 * rounds, struct.pack("<" + "i" * rounds, *results)
