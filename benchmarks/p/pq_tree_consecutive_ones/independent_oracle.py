"""Small-instance PQ-family validation by frontier and interval enumeration."""

from __future__ import annotations

import itertools
import struct


def _is_frontier(order: tuple[int, ...], masks: tuple[int, ...]) -> bool:
    positions = [0] * len(order)
    for position, column in enumerate(order):
        positions[column] = position
    for mask in masks:
        chosen = [positions[column] for column in range(len(order)) if mask >> column & 1]
        if chosen and max(chosen) - min(chosen) + 1 != len(chosen):
            return False
    return True


def _common_intervals(frontiers: set[tuple[int, ...]], n: int) -> set[frozenset[int]]:
    intervals = None
    for frontier in frontiers:
        current = {frozenset(frontier[left:right + 1])
                   for left in range(n) for right in range(left, n)}
        intervals = current if intervals is None else intervals & current
    return intervals or set()


def _overlap(left: frozenset[int], right: frozenset[int]) -> bool:
    return bool(left & right) and not left <= right and not right <= left


def _encode_family(frontiers: set[tuple[int, ...]], n: int) -> list[int]:
    if not frontiers:
        return [0, 0, 0]
    intervals = _common_intervals(frontiers, n)
    strong = {candidate for candidate in intervals
              if not any(_overlap(candidate, other) for other in intervals)}

    def build(block: frozenset[int]):
        if len(block) == 1:
            return (0, next(iter(block)), [])
        proper = [candidate for candidate in strong
                  if candidate < block and candidate]
        maximal = [candidate for candidate in proper
                   if not any(candidate < other < block for other in proper)]
        maximal.sort(key=lambda child: min(child))
        if not maximal or set().union(*maximal) != set(block):
            raise ValueError("strong-interval partition did not cover a block")
        children = [build(child) for child in maximal]

        def projection(frontier: tuple[int, ...]) -> tuple[int, ...]:
            owner = {}
            for child_index, child in enumerate(maximal):
                for column in child:
                    owner[column] = child_index
            seen = []
            for column in frontier:
                if column in owner and (not seen or seen[-1] != owner[column]):
                    seen.append(owner[column])
            return tuple(seen)

        orders = {projection(frontier) for frontier in frontiers}
        degree = len(children)
        if len(orders) == __import__("math").factorial(degree):
            kind = 1
        elif degree >= 3 and len(orders) == 2:
            sample = next(iter(orders))
            if tuple(reversed(sample)) not in orders:
                raise ValueError("two-order node is not a reversal pair")
            kind = 2
        else:
            raise ValueError("frontier family is not represented by a reduced PQ node")
        if kind == 1:
            children.sort(key=_recursive_key)
        else:
            reverse = list(reversed(children))
            if tuple(_recursive_key(child) for child in reverse) < tuple(
                    _recursive_key(child) for child in children):
                children = reverse
        return kind, degree, children

    def _recursive_key(node):
        kind, arg, children = node
        if kind == 0:
            return kind, arg
        return kind, arg, tuple(_recursive_key(child) for child in children)

    root = build(frozenset(range(n)))
    words = [1, len(frontiers), 0]

    def write(node):
        kind, argument, children = node
        words.extend((kind, argument))
        words[2] += 1
        for child in children:
            write(child)

    write(root)
    return words


def expected_output(values: list[int] | tuple[int, ...], *, max_n: int = 8) -> tuple[int, bytes]:
    """Build the exact canonical result independently for n<=8.

    This enumerates the solution family, derives its strong-interval tree, and
    classifies each node by its complete set of child orders. It does not use
    PQ reduction templates.
    """
    if len(values) < 2:
        return -1, b""
    n, row_count = values[0], values[1]
    if not 2 <= n <= max_n or not 0 <= row_count <= 32 or len(values) != 2 + row_count:
        return -1, b""
    if any(mask < 0 or mask >= 1 << n for mask in values[2:]):
        return -1, b""
    masks = tuple(values[2:])
    frontiers = {order for order in itertools.permutations(range(n))
                 if _is_frontier(order, masks)}
    words = _encode_family(frontiers, n)
    payload = b"".join(struct.pack("<q", word) for word in words)
    return len(payload), payload
