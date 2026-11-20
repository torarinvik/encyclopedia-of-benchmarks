"""Algorithmic reference for the bounded UnShuffle sort profile."""

from __future__ import annotations

from collections.abc import Sequence
import heapq

MAX_LENGTH = 1024


def expected_result(values: Sequence[int]) -> list[int]:
    """Distribute into ordered endpoint piles, then merge pile heads by heap."""
    if len(values) > MAX_LENGTH:
        raise ValueError("input exceeds the UnShuffle sort profile")

    piles: list[list[int]] = []
    for value in values:
        for pile in piles:
            if value <= pile[0]:
                pile.insert(0, value)
                break
            if value >= pile[-1]:
                pile.append(value)
                break
        else:
            piles.append([value])

    heap: list[tuple[int, int, int]] = []
    for pile_index, pile in enumerate(piles):
        heapq.heappush(heap, (pile[0], pile_index, 0))

    output: list[int] = []
    while heap:
        value, pile_index, offset = heapq.heappop(heap)
        output.append(value)
        next_offset = offset + 1
        if next_offset < len(piles[pile_index]):
            heapq.heappush(
                heap,
                (piles[pile_index][next_offset], pile_index, next_offset),
            )
    return output
