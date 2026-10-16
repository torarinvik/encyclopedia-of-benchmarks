"""Portable reference for TheAlgorithms/C-Sharp's AsconDigest implementation."""

from __future__ import annotations

MASK64 = (1 << 64) - 1
INITIAL_STATES = (
    (0xEE9398AADB67F03D, 0x8BB21831C60F1002, 0xB48A92DB98D5DA62,
     0x43189921B8F8E3E8, 0x348FA5C9D525E140),
    (0x01470194FC6528A6, 0x738EC38AC0ADFFA7, 0x2EC8E3296C76384C,
     0xD6F6A54D7F52377D, 0xA13C42A223BE8D87),
)


def _rotate_right(value: int, count: int) -> int:
    return ((value >> count) | (value << (64 - count))) & MASK64


def _permute(state: list[int], rounds: int) -> None:
    constants = ((0xF0, 0xE1, 0xD2, 0xC3) if rounds == 12 else ()) + (
        0xB4, 0xA5, 0x96, 0x87, 0x78, 0x69, 0x5A, 0x4B,
    )
    for constant in constants:
        x0, x1, x2, x3, x4 = state
        t0 = x0 ^ x1 ^ x2 ^ x3 ^ constant ^ (x1 & (x0 ^ x2 ^ x4 ^ constant))
        t1 = x0 ^ x2 ^ x3 ^ x4 ^ constant ^ ((x1 ^ x2 ^ constant) & (x1 ^ x3))
        t2 = x1 ^ x2 ^ x4 ^ constant ^ (x3 & x4)
        t3 = x0 ^ x1 ^ x2 ^ constant ^ ((~x0) & (x3 ^ x4))
        t4 = x1 ^ x3 ^ x4 ^ ((x0 ^ x4) & x1)
        state[:] = (
            (t0 ^ _rotate_right(t0, 19) ^ _rotate_right(t0, 28)) & MASK64,
            (t1 ^ _rotate_right(t1, 39) ^ _rotate_right(t1, 61)) & MASK64,
            (~(t2 ^ _rotate_right(t2, 1) ^ _rotate_right(t2, 6))) & MASK64,
            (t3 ^ _rotate_right(t3, 10) ^ _rotate_right(t3, 17)) & MASK64,
            (t4 ^ _rotate_right(t4, 7) ^ _rotate_right(t4, 41)) & MASK64,
        )


def ascon_digest(data: bytes, variant: int) -> bytes:
    """Return the exact 32-byte result produced by the pinned C# source."""
    state = list(INITIAL_STATES[variant])
    rounds = 12 if variant == 0 else 8
    complete_length = len(data) - (len(data) % 8)
    for offset in range(0, complete_length, 8):
        state[0] ^= int.from_bytes(data[offset:offset + 8], "big")
        _permute(state, rounds)

    tail = data[complete_length:]
    final_word = int.from_bytes(tail + b"\x80" + bytes(7 - len(tail)), "big")
    state[0] ^= final_word
    # The pinned source calls P(12) here for both variants.
    _permute(state, 12)

    output = bytearray()
    for index in range(4):
        output.extend(state[0].to_bytes(8, "big"))
        if index != 3:
            _permute(state, rounds)
    return bytes(output)


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    variant, length = values[:2]
    if (variant not in (0, 1) or not 0 <= length <= 4096
            or len(values) != length + 2
            or any(not 0 <= value <= 255 for value in values[2:])):
        return -1, b""
    output = ascon_digest(bytes(values[2:]), variant)
    return len(output), output

