"""Exact bounded nearest-neighbor-interchange distance oracle."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_LEAVES = 7
MAX_EDGES = 11
MAX_INPUT = 23
MAX_STATES = 945
MAX_OUTPUT_BYTES = 8


def _valid_tree(splits: Sequence[int], n: int) -> bool:
    edges = 2 * n - 3
    universe = (1 << n) - 1
    if len(splits) != edges or any(type(x) is not int for x in splits):
        return False
    if any(x <= 0 or x >= universe or x & 1 for x in splits) or len(set(splits)) != edges:
        return False
    pendants = {(1 << leaf) for leaf in range(1, n)} | {universe ^ 1}
    if not pendants.issubset(splits):
        return False
    internal = [x for x in splits if 2 <= x.bit_count() <= n - 2]
    if len(internal) != n - 3:
        return False
    for i, left in enumerate(internal):
        for right in internal[i + 1:]:
            common = left & right
            if common and common != left and common != right:
                return False
    return True


def _parse(values: Sequence[int] | None) -> tuple[int, list[int], list[int]] | None:
    if (not isinstance(values, (tuple, list)) or not 7 <= len(values) <= MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if not 3 <= n <= MAX_LEAVES:
        return None
    edges = 2 * n - 3
    if len(values) != 1 + 2 * edges:
        return None
    first = list(values[1:1 + edges])
    second = list(values[1 + edges:])
    if not _valid_tree(first, n) or not _valid_tree(second, n):
        return None
    return n, first, second


def _all_topologies(n: int) -> list[tuple[int, ...]]:
    """Enumerate rooted-at-leaf-0 split sets by inserting leaves on edges."""
    current = [(2, 4, 6)]
    for leaves in range(4, n + 1):
        new_bit = 1 << (leaves - 1)
        next_states: set[tuple[int, ...]] = set()
        for old in current:
            for selected in old:
                expanded: list[int] = []
                for split in old:
                    if split == selected:
                        expanded.extend((split, split | new_bit))
                    elif selected & split == selected:
                        expanded.append(split | new_bit)
                    else:
                        expanded.append(split)
                expanded.append(new_bit)
                next_states.add(tuple(sorted(expanded)))
        current = sorted(next_states)
    return current


def _distance(n: int, first: Sequence[int], second: Sequence[int]) -> int:
    states = _all_topologies(n)
    start = tuple(sorted(first))
    goal = tuple(sorted(second))
    edge_count = 2 * n - 3
    start_index = states.index(start)
    goal_index = states.index(goal)
    distances = [-1] * len(states)
    distances[start_index] = 0
    queue = deque([start_index])
    while queue:
        current = queue.popleft()
        if current == goal_index:
            return distances[current]
        for candidate, state in enumerate(states):
            if distances[candidate] != -1:
                continue
            common = sum(1 for split in states[current] if split in state)
            if common == edge_count - 1:
                distances[candidate] = distances[current] + 1
                queue.append(candidate)
    return -1


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, first, second = parsed
    payload = struct.pack("<q", _distance(n, first, second))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
