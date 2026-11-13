"""Aho–Corasick occurrence counts via reverse failure-tree aggregation."""

from __future__ import annotations

import struct
from collections import deque
from typing import Sequence

MAX_PATTERNS = 16
MAX_PATTERN_LENGTH = 32
MAX_TEXT_LENGTH = 256
MAX_NODES = 1 + MAX_PATTERNS * MAX_PATTERN_LENGTH
MAX_VALID_INPUT_LENGTH = 2 + MAX_PATTERNS + MAX_PATTERNS * MAX_PATTERN_LENGTH + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_PATTERNS * 8
INVALID = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[list[int]], list[int]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 3
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(type(value) is not int for value in values)):
        return None
    pattern_count, text_length = values[0], values[1]
    if not 1 <= pattern_count <= MAX_PATTERNS or not 0 <= text_length <= MAX_TEXT_LENGTH:
        return None
    if len(values) < 2 + pattern_count:
        return None
    lengths = values[2:2 + pattern_count]
    if any(type(length) is not int or not 1 <= length <= MAX_PATTERN_LENGTH for length in lengths):
        return None
    offset = 2 + pattern_count
    patterns: list[list[int]] = []
    for length in lengths:
        end = offset + length
        if end > len(values):
            return None
        pattern = list(values[offset:end])
        if any(symbol < 1 or symbol > 4 for symbol in pattern):
            return None
        patterns.append(pattern)
        offset = end
    text = list(values[offset:])
    if len(text) != text_length or any(symbol < 1 or symbol > 4 for symbol in text):
        return None
    if len({tuple(pattern) for pattern in patterns}) != pattern_count:
        return None
    return patterns, text


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return ``(byte_count, payload)`` for bounded pattern/text symbols 1..4."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    patterns, text = parsed
    output_size = len(patterns) * 8
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null or effective_capacity < output_size):
        return OUTPUT_ERROR, b""

    transitions = [[-1] * 5]
    failure = [0]
    terminal = [-1]
    pattern_nodes: list[int] = []
    for pattern_index, pattern in enumerate(patterns):
        state = 0
        for symbol in pattern:
            target = transitions[state][symbol]
            if target == -1:
                target = len(transitions)
                transitions[state][symbol] = target
                transitions.append([-1] * 5)
                failure.append(0)
                terminal.append(-1)
            state = target
        terminal[state] = pattern_index
        pattern_nodes.append(state)

    order: list[int] = []
    queue: deque[int] = deque()
    for symbol in range(1, 5):
        child = transitions[0][symbol]
        if child != -1:
            queue.append(child)
    while queue:
        state = queue.popleft()
        order.append(state)
        for symbol in range(1, 5):
            child = transitions[state][symbol]
            if child == -1:
                continue
            suffix = failure[state]
            while suffix != 0 and transitions[suffix][symbol] == -1:
                suffix = failure[suffix]
            target = transitions[suffix][symbol]
            if target != -1:
                suffix = target
            failure[child] = suffix
            queue.append(child)

    visits = [0] * len(transitions)
    state = 0
    for symbol in text:
        while state != 0 and transitions[state][symbol] == -1:
            state = failure[state]
        target = transitions[state][symbol]
        if target != -1:
            state = target
        visits[state] += 1
    for child in reversed(order):
        visits[failure[child]] += visits[child]

    payload = b"".join(struct.pack("<q", visits[node]) for node in pattern_nodes)
    return len(payload), payload
