"""Independent one-block Ethereum Keccak-256 oracle for string_hash_equality."""
from __future__ import annotations

from typing import Sequence

MAX_BYTES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_BYTES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
RATE_BYTES = 136
MASK64 = (1 << 64) - 1
ROTATION_OFFSETS = (
    0, 1, 62, 28, 27,
    36, 44, 6, 55, 20,
    3, 10, 43, 25, 39,
    41, 45, 15, 21, 8,
    18, 2, 61, 56, 14,
)
ROUND_CONSTANTS = (
    0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
    0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
    0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
    0x000000008000808B, 0x800000000000008B, 0x8000000080008089, 0x8000000000008003,
    0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
    0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
)
KECCAK256_KNOWN_VECTORS = {
    b"": bytes.fromhex("c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"),
    b"abc": bytes.fromhex("4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45"),
}


def _rotate_left(value: int, amount: int) -> int:
    if amount == 0:
        return value & MASK64
    return ((value << amount) | (value >> (64 - amount))) & MASK64


def _keccak_f1600(state: list[int]) -> None:
    for round_constant in ROUND_CONSTANTS:
        column = [state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20] for x in range(5)]
        delta = [column[(x + 4) % 5] ^ _rotate_left(column[(x + 1) % 5], 1) for x in range(5)]
        moved = [0] * 25
        for y in range(5):
            for x in range(5):
                source = x + 5 * y
                target = y + 5 * ((2 * x + 3 * y) % 5)
                moved[target] = _rotate_left(state[source] ^ delta[x], ROTATION_OFFSETS[source])
        for y in range(5):
            for x in range(5):
                state[x + 5 * y] = moved[x + 5 * y] ^ ((~moved[(x + 1) % 5 + 5 * y] & MASK64) & moved[(x + 2) % 5 + 5 * y])
        state[0] ^= round_constant


def keccak256(message: bytes) -> bytes:
    """Return Ethereum Keccak-256 for one bounded message (0..64 bytes)."""
    if not isinstance(message, bytes) or len(message) > MAX_BYTES:
        raise ValueError("message must be bytes with length at most 64")
    block = bytearray(RATE_BYTES)
    block[:len(message)] = message
    block[len(message)] ^= 0x01
    block[-1] ^= 0x80
    state = [int.from_bytes(block[i:i + 8], "little") for i in range(0, RATE_BYTES, 8)] + [0] * 8
    _keccak_f1600(state)
    return b"".join(lane.to_bytes(8, "little") for lane in state[:4])


def expected_result(values: Sequence[int]) -> int:
    """Return 1/0 for equal/different Keccak digests, or -1 for invalid input."""
    if (
        not isinstance(values, (tuple, list))
        or len(values) < 2
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT
    length_a, length_b = values[0], values[1]
    if not 0 <= length_a <= MAX_BYTES or not 0 <= length_b <= MAX_BYTES:
        return INVALID_RESULT
    if len(values) != 2 + length_a + length_b:
        return INVALID_RESULT
    payload = values[2:]
    if any(byte < 0 or byte > 255 for byte in payload):
        return INVALID_RESULT
    bytes_a = bytes(payload[:length_a])
    bytes_b = bytes(payload[length_a:])
    return int(keccak256(bytes_a) == keccak256(bytes_b))
