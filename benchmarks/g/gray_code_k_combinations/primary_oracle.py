"""Primary reference using reflected Gray-code filtering."""

from __future__ import annotations

from math import comb
from typing import Sequence

INVALID = -1


def _parse(values: Sequence[int]) -> tuple[int, int] | None:
    if len(values) != 2:
        return None
    n, k = values
    if not 0 <= n <= 12 or not 0 <= k <= n:
        return None
    return n, k


def evaluate(values: Sequence[int]) -> tuple[int, bytes]:
    """Return `(combination_count, encoded_masks)` or `(-1, b"")`."""
    parsed = _parse(values)
    if parsed is None:
        return INVALID, b""
    n, k = parsed
    masks: list[int] = []
    for index in range(1 << n):
        mask = index ^ (index >> 1)
        if mask.bit_count() == k:
            masks.append(mask)
    result = comb(n, k)
    encoded = bytearray((result & 255, (result >> 8) & 255))
    for mask in masks:
        encoded.extend((mask & 255, (mask >> 8) & 255))
    return result, bytes(encoded)


if __name__ == "__main__":
    raise SystemExit("This oracle is imported by package tooling; no runner is bundled.")
