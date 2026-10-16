"""Source contract for flattening a bounded nested-list marker stream."""
from __future__ import annotations

MAX_INPUT_LENGTH = 255
OPEN = -(1 << 63)
CLOSE = OPEN + 1
LEAF_MIN = -1_000_000
LEAF_MAX = 1_000_000
INVALID_RESULT = -1
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1


def expected_result(values: list[int]) -> int:
    if not values or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    depth = 0
    root_closed = False
    h = FNV_OFFSET
    for index, token in enumerate(values):
        if token == OPEN:
            if root_closed or (depth == 0 and index != 0):
                return INVALID_RESULT
            depth += 1
            if depth > 16:
                return INVALID_RESULT
        elif token == CLOSE:
            if depth == 0:
                return INVALID_RESULT
            depth -= 1
            if depth == 0:
                root_closed = True
                if index != len(values) - 1:
                    return INVALID_RESULT
        elif LEAF_MIN <= token <= LEAF_MAX and depth > 0:
            for byte in int(token).to_bytes(8, "little", signed=True):
                h = ((h ^ byte) * FNV_PRIME) & MASK64
        else:
            return INVALID_RESULT
    if depth != 0 or not root_closed:
        return INVALID_RESULT
    return h if h < (1 << 63) else h - (1 << 64)
