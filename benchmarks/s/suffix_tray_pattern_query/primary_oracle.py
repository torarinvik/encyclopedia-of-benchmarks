"""Suffix-tray construction and pattern-query reference for a small text."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from dataclasses import dataclass, field

MAX_TEXT = 12
MAX_PATTERN = 8
MAX_SIGMA = 4
MAX_VALID_INPUT_LENGTH = 23
MAX_PARSEABLE_INPUT_LENGTH = 24
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 16
WORKSPACE_BYTES = 16_384


@dataclass
class _Node:
    edge_start: int
    edge_length: int
    depth: int
    leaf_start: int = -1
    children: dict[int, int] = field(default_factory=dict)
    leaf_count: int = 0
    sa_left: int = 0
    sa_right: int = -1
    sigma: bool = False
    sigma_children: list[int] = field(default_factory=list)
    kind: int = 0  # 0: non-sigma; 1: branching sigma; 2: unary sigma; 3: sigma leaf
    child_by_symbol: list[int] = field(default_factory=list)
    group_by_symbol: list[int] = field(default_factory=list)
    separator: int = -1
    only_sigma_child: int = -1
    left_interval: tuple[int, int] | None = None
    right_interval: tuple[int, int] | None = None


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or
            not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH or
            any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                for value in values)):
        return None
    sigma, n, q = values[:3]
    if not 2 <= sigma <= MAX_SIGMA or not 1 <= n <= MAX_TEXT or not 1 <= q <= MAX_PATTERN:
        return None
    if len(values) != 3 + n + q:
        return None
    text = list(values[3:3 + n])
    pattern = list(values[3 + n:])
    if any(not 0 <= symbol < sigma for symbol in text + pattern):
        return None
    return sigma, text, pattern


def _suffix_array(terminated: list[int]) -> list[int]:
    suffixes = list(range(len(terminated)))
    for i in range(1, len(suffixes)):
        item = suffixes[i]
        j = i
        while j > 0 and terminated[item:] < terminated[suffixes[j - 1]:]:
            suffixes[j] = suffixes[j - 1]
            j -= 1
        suffixes[j] = item
    return suffixes


def _insert_suffix(nodes: list[_Node], terminated: list[int], start: int) -> None:
    current = 0
    position = start
    while position < len(terminated):
        symbol = terminated[position]
        child_id = nodes[current].children.get(symbol, -1)
        if child_id < 0:
            child_id = len(nodes)
            edge_length = len(terminated) - position
            nodes.append(_Node(position, edge_length,
                               nodes[current].depth + edge_length,
                               leaf_start=start))
            nodes[current].children[symbol] = child_id
            return

        child = nodes[child_id]
        common = 0
        while (common < child.edge_length and
               position + common < len(terminated) and
               terminated[position + common] == terminated[child.edge_start + common]):
            common += 1
        if common == child.edge_length:
            position += common
            current = child_id
            continue

        # Split the existing compressed edge at its first differing symbol.
        split_id = len(nodes)
        split = _Node(child.edge_start, common, nodes[current].depth + common)
        nodes.append(split)
        nodes[current].children[symbol] = split_id
        child.edge_start += common
        child.edge_length -= common
        split.children[terminated[child.edge_start]] = child_id
        new_start = position + common
        new_id = len(nodes)
        new_length = len(terminated) - new_start
        nodes.append(_Node(new_start, new_length, split.depth + new_length,
                           leaf_start=start))
        split.children[terminated[new_start]] = new_id
        return


def _prepare(text: list[int], sigma: int):
    # The unique terminal sorts below every text symbol, matching the ordinary
    # lexicographic order of finite suffixes while making every leaf explicit.
    terminated = [*text, -1]
    suffixes = _suffix_array(terminated)
    rank = [0] * len(suffixes)
    for index, start in enumerate(suffixes):
        rank[start] = index

    # A bounded direct suffix insertion builds the compact suffix tree used as
    # the input structure for the source's tray transformation.
    nodes = [_Node(0, 0, 0)]
    for start in range(len(terminated)):
        _insert_suffix(nodes, terminated, start)

    def summarize(node_id: int) -> tuple[int, int, int]:
        node = nodes[node_id]
        if node.leaf_start >= 0:
            r = rank[node.leaf_start]
            node.leaf_count = 1
            node.sa_left = r
            node.sa_right = r
            return 1, r, r
        child_ids = sorted(node.children.values(), key=lambda c: terminated[nodes[c].edge_start])
        node.children = {terminated[nodes[c].edge_start]: c for c in child_ids}
        total = 0
        left = len(suffixes)
        right = -1
        for child_id in child_ids:
            count, child_left, child_right = summarize(child_id)
            total += count
            left = min(left, child_left)
            right = max(right, child_right)
        node.leaf_count = total
        node.sa_left = left
        node.sa_right = right
        return total, left, right

    summarize(0)

    # Chapter 422 / §3.2: retain sigma nodes, replace consecutive groups of
    # non-sigma children by suffix-interval nodes, and materialize the
    # branching-node alphabet map or unary-node separator.
    for node_id, node in enumerate(nodes):
        node.sigma = node.leaf_count >= sigma
        if not node.sigma:
            continue
        ordered_children = list(node.children.values())
        node.sigma_children = [c for c in ordered_children if nodes[c].sigma]
        if len(node.sigma_children) == 0:
            node.kind = 3
            continue

        if len(node.sigma_children) >= 2:
            node.kind = 1
            node.child_by_symbol = [-1] * sigma
            node.group_by_symbol = [-1] * sigma
            sigma_position = {child: i for i, child in enumerate(node.sigma_children)}
            gaps: list[tuple[int, int] | None] = []
            pending: list[int] = []
            sigma_seen = 0
            for child in ordered_children:
                if child in sigma_position:
                    if pending:
                        lo = nodes[pending[0]].sa_left
                        hi = nodes[pending[-1]].sa_right
                        gaps.append((lo, hi))
                    else:
                        gaps.append(None)
                    pending = []
                    sigma_seen += 1
                else:
                    pending.append(child)
            if pending:
                gaps.append((nodes[pending[0]].sa_left, nodes[pending[-1]].sa_right))
            else:
                gaps.append(None)

            sigma_first_chars = [terminated[nodes[c].edge_start] for c in node.sigma_children]
            for symbol in range(sigma):
                if symbol in sigma_first_chars:
                    node.child_by_symbol[symbol] = node.sigma_children[sigma_first_chars.index(symbol)]
                    continue
                gap_index = sum(1 for first in sigma_first_chars if first < symbol)
                if gaps[gap_index] is not None:
                    node.group_by_symbol[symbol] = gap_index
            node._interval_gaps = gaps  # bounded auxiliary list used by the query
        else:
            node.kind = 2
            child_id = node.sigma_children[0]
            node.only_sigma_child = child_id
            node.separator = terminated[nodes[child_id].edge_start]
            child_position = ordered_children.index(child_id)
            left_children = ordered_children[:child_position]
            right_children = ordered_children[child_position + 1:]
            if left_children:
                node.left_interval = (nodes[left_children[0]].sa_left,
                                     nodes[left_children[-1]].sa_right)
            if right_children:
                node.right_interval = (nodes[right_children[0]].sa_left,
                                      nodes[right_children[-1]].sa_right)

    return terminated, suffixes, nodes


def _suffix_compare(terminated: list[int], suffix_start: int,
                    pattern: list[int], start_at: int) -> tuple[int, int]:
    i = start_at
    while i < len(pattern) and suffix_start + i < len(terminated):
        a = terminated[suffix_start + i]
        b = pattern[i]
        if a != b:
            return (-1 if a < b else 1), i
        i += 1
    if i == len(pattern):
        return 1, i
    return -1, i


def _search_interval(terminated: list[int], pattern: list[int], suffixes: list[int],
                     lo: int, hi: int, known_prefix: int) -> int | None:
    low = lo - 1
    high = hi + 1
    low_lcp = known_prefix
    high_lcp = known_prefix
    while high - low > 1:
        middle = (low + high) // 2
        start_at = min(low_lcp, high_lcp)
        comparison, lcp = _suffix_compare(terminated, suffixes[middle], pattern, start_at)
        if comparison < 0:
            low = middle
            low_lcp = lcp
        else:
            high = middle
            high_lcp = lcp
    if high > hi:
        return None
    suffix_start = suffixes[high]
    if suffix_start + len(pattern) > len(terminated):
        return None
    if terminated[suffix_start:suffix_start + len(pattern)] != pattern:
        return None
    return suffix_start


def _tray_query(text: list[int], pattern: list[int], sigma: int) -> int:
    terminated, suffixes, nodes = _prepare(text, sigma)
    current = 0
    matched = 0
    while True:
        node = nodes[current]
        if matched == len(pattern):
            return suffixes[node.sa_left]
        if not node.sigma or node.kind == 3:
            found = _search_interval(terminated, pattern, suffixes,
                                     node.sa_left, node.sa_right, matched)
            return -1 if found is None else found

        symbol = pattern[matched]
        if node.kind == 1:
            child_id = node.child_by_symbol[symbol]
            if child_id >= 0:
                destination = (nodes[child_id].sa_left, nodes[child_id].sa_right)
                next_node = child_id
            else:
                group = node.group_by_symbol[symbol]
                if group < 0:
                    return -1
                interval = node._interval_gaps[group]
                if interval is None:
                    return -1
                found = _search_interval(terminated, pattern, suffixes,
                                         interval[0], interval[1], matched)
                return -1 if found is None else found
        else:
            child_id = node.only_sigma_child
            if symbol == node.separator:
                destination = (nodes[child_id].sa_left, nodes[child_id].sa_right)
                next_node = child_id
            else:
                interval = node.left_interval if symbol < node.separator else node.right_interval
                if interval is None:
                    return -1
                found = _search_interval(terminated, pattern, suffixes,
                                         interval[0], interval[1], matched)
                return -1 if found is None else found

        child = nodes[next_node]
        representative = suffixes[destination[0]]
        edge_begin = node.depth
        edge_end = child.depth
        while matched < len(pattern) and edge_begin < edge_end:
            text_symbol = terminated[representative + edge_begin]
            if pattern[matched] != text_symbol:
                return -1
            matched += 1
            edge_begin += 1
        if matched == len(pattern):
            return suffixes[child.sa_left]
        if edge_begin != edge_end:
            return -1
        current = next_node


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or
            capacity is not None and (type(capacity) is not int or capacity < 0) or
            input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH) or
            input_is_null and values not in (None, [], ()) or
            not input_is_null and values is not None and input_length is not None and
            isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    sigma, text, pattern = parsed
    position = _tray_query(text, pattern, sigma)
    result = (0, -1) if position < 0 else (1, position)
    output = struct.pack("<qq", *result)
    return len(output), output
