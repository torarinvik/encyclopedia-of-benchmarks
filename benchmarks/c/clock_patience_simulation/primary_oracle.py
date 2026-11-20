"""Direct pile-by-pile simulation for the bounded Clock Patience profile."""

from __future__ import annotations

PILE_COUNT = 13
CARDS_PER_PILE = 4
CARD_COUNT = PILE_COUNT * CARDS_PER_PILE


def _valid(values: list[int] | None, is_null: bool = False, length: int | None = None) -> bool:
    if is_null or not isinstance(values, list) or len(values) != CARD_COUNT:
        return False
    if length is not None and length != CARD_COUNT:
        return False
    counts = [0] * (PILE_COUNT + 1)
    for value in values:
        if type(value) is not int or not 1 <= value <= PILE_COUNT:
            return False
        counts[value] += 1
    return all(counts[rank] == CARDS_PER_PILE for rank in range(1, PILE_COUNT + 1))


def expected_result(values: list[int] | None, is_null: bool = False,
                    length: int | None = None) -> int:
    """Return 1 if the revealed-card chain exposes all 52 cards, else 0."""
    if not _valid(values, is_null, length):
        return -1
    assert values is not None
    positions = [0] * PILE_COUNT
    pile = PILE_COUNT - 1
    revealed = 0
    while positions[pile] < CARDS_PER_PILE:
        rank = values[pile * CARDS_PER_PILE + positions[pile]]
        positions[pile] += 1
        revealed += 1
        pile = rank - 1
    return int(revealed == CARD_COUNT)
