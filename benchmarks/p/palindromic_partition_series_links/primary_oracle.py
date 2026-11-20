"""Series-link eertree reference for bounded minimum palindrome partitioning."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT_LENGTH = 64
ALPHABET_SIZE = 4
MAX_VALID_INPUT_LENGTH = MAX_TEXT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_TEXT_LENGTH + 1)
WORKSPACE_BYTES = 16_384
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> list[int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if not 0 <= n <= MAX_TEXT_LENGTH or len(values) != n + 1:
        return None
    text = list(values[1:])
    if any(not 0 <= symbol < ALPHABET_SIZE for symbol in text):
        return None
    return text


def _find_extendable(lengths: list[int], links: list[int], text: list[int],
                     position: int, start: int) -> int:
    node = start
    while True:
        preceding = position - 1 - lengths[node]
        if preceding >= 0 and text[preceding] == text[position]:
            return node
        node = links[node]


def _solve(text: list[int]) -> list[int]:
    lengths = [-1, 0]
    links = [0, 0]
    transitions: list[dict[int, int]] = [{}, {}]
    differences = [0, 0]
    series_links = [0, 0]
    series_best = [0, 0]
    series_start = [0, 0]
    longest_suffix = 1
    dp = [0] + [MAX_TEXT_LENGTH + 1] * len(text)
    predecessor = [0] * (len(text) + 1)

    for position, symbol in enumerate(text):
        end = position + 1
        parent = _find_extendable(lengths, links, text, position, longest_suffix)
        next_node = transitions[parent].get(symbol)
        if next_node is None:
            next_node = len(lengths)
            lengths.append(lengths[parent] + 2)
            links.append(0)
            transitions.append({})
            differences.append(0)
            series_links.append(0)
            series_best.append(0)
            series_start.append(0)
            transitions[parent][symbol] = next_node
            if lengths[next_node] == 1:
                links[next_node] = 1
            else:
                suffix_parent = _find_extendable(
                    lengths, links, text, position, links[parent]
                )
                links[next_node] = transitions[suffix_parent][symbol]
            differences[next_node] = lengths[next_node] - lengths[links[next_node]]
            if differences[next_node] == differences[links[next_node]]:
                series_links[next_node] = series_links[links[next_node]]
            else:
                series_links[next_node] = links[next_node]

        longest_suffix = next_node
        best_value = MAX_TEXT_LENGTH + 1
        best_start = end
        node = longest_suffix
        while lengths[node] > 0:
            start = end - lengths[series_links[node]] - differences[node]
            series_best[node] = dp[start]
            series_start[node] = start
            fail = links[node]
            if differences[node] == differences[fail]:
                if (series_best[fail] < series_best[node]
                        or (series_best[fail] == series_best[node]
                            and series_start[fail] < series_start[node])):
                    series_best[node] = series_best[fail]
                    series_start[node] = series_start[fail]
            candidate = series_best[node] + 1
            if (candidate < best_value
                    or (candidate == best_value and series_start[node] < best_start)):
                best_value = candidate
                best_start = series_start[node]
            node = series_links[node]
        dp[end] = best_value
        predecessor[end] = best_start

    pieces: list[int] = []
    end = len(text)
    while end > 0:
        start = predecessor[end]
        pieces.append(end - start)
        end = start
    pieces.reverse()
    return [len(pieces), *pieces]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    text = _decode(values, input_length, input_is_null)
    if text is None:
        return -1, b""
    words = _solve(text)
    payload = b"".join(struct.pack("<q", word) for word in words)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or len(payload) > effective_capacity:
        return -2, b""
    return len(payload), payload
