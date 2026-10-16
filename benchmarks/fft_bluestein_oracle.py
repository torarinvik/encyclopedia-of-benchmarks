"""Bounded forward Bluestein transform contract and direct-DFT oracle."""
from __future__ import annotations
import math
import struct

MAX_N = 8
MAX_INPUT_LENGTH = MAX_N + 1
MAX_OUTPUT_BYTES = MAX_N * 16
SCALE = 1_000_000
INVALID = -1
INSUFFICIENT = -2

def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if len(values) < 1 or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return INVALID, b""
    n = values[0]
    if not (1 <= n <= MAX_N and len(values) == n + 1 and all(-8 <= v <= 8 for v in values[1:])):
        return INVALID, b""
    components = []
    for k in range(n):
        re = im = 0.0
        for j, sample in enumerate(values[1:]):
            angle = -2.0 * math.pi * j * k / n
            re += sample * math.cos(angle)
            im += sample * math.sin(angle)
        for component in (re, im):
            scaled = component * SCALE
            components.append(math.floor(scaled + 0.5) if scaled >= 0 else math.ceil(scaled - 0.5))
    payload = b"".join(struct.pack("<q", item) for item in components)
    if capacity is not None and capacity < len(payload):
        return INSUFFICIENT, b""
    return len(payload), payload
