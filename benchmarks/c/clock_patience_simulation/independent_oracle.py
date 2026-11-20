"""Bottom-card directed-tree characterization of Clock Patience outcomes."""

from __future__ import annotations

PILE_COUNT = 13
CARDS_PER_PILE = 4
CARD_COUNT = PILE_COUNT * CARDS_PER_PILE


def _valid(values: list[int] | None, is_null: bool = False, length: int | None = None) -> bool:
    if is_null or not isinstance(values, list) or len(values) != CARD_COUNT:
        return False
    if length is not None and length != CARD_COUNT:
        return False
    rank_counts = [0] * (PILE_COUNT + 1)
    for rank in values:
        if type(rank) is not int or not 1 <= rank <= PILE_COUNT:
            return False
        rank_counts[rank] += 1
    return all(count == CARDS_PER_PILE for count in rank_counts[1:])


def expected_result(values: list[int] | None, is_null: bool = False,
                    length: int | None = None) -> int:
    """Test whether every non-center pile reaches the center in the bottom graph.

    Knuth's characterization gives each of piles 1..12 one arc to the pile
    named by its bottom card. The deal wins exactly when these arcs form a tree
    spanning the 13 piles, rooted at the center. The center bottom card is
    deliberately ignored.
    """
    if not _valid(values, is_null, length):
        return -1
    assert values is not None
    parent = [values[pile * CARDS_PER_PILE + CARDS_PER_PILE - 1] - 1
              for pile in range(PILE_COUNT - 1)]
    root = PILE_COUNT - 1
    for start in range(PILE_COUNT - 1):
        seen = 0
        current = start
        while current != root:
            bit = 1 << current
            if seen & bit:
                return 0
            seen |= bit
            current = parent[current]
    return 1
