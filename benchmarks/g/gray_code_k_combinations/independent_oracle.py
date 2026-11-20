"""Independent direct generator for fixed-weight reflected Gray sequences."""

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
    """Return `(combination_count, encoded_masks)` from the recursive recurrence."""
    parsed = _parse(values)
    if parsed is None:
        return INVALID, b""
    n, k = parsed
    masks: list[int] = []

    def generate(size: int, remaining: int, mask: int, reverse: bool) -> None:
        if remaining < 0 or remaining > size:
            return
        if size == 0:
            masks.append(mask)
            return
        bit = 1 << (size - 1)
        if reverse:
            generate(size - 1, remaining - 1, mask | bit, False)
            generate(size - 1, remaining, mask, True)
        else:
            generate(size - 1, remaining, mask, False)
            generate(size - 1, remaining - 1, mask | bit, True)

    generate(n, k, 0, False)
    result = comb(n, k)
    encoded = bytearray((result & 255, (result >> 8) & 255))
    for mask in masks:
        encoded.extend((mask & 255, (mask >> 8) & 255))
    return result, bytes(encoded)


if __name__ == "__main__":
    raise SystemExit("This oracle is imported by package tooling; no runner is bundled.")
