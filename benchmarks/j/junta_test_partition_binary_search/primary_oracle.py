"""Mask-oriented replay of the Chapter 709 / Blais JuntaTest kernel."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
K = 1
EPSILON = 1
ROUNDS = 24
MAX_VALID_INPUT_LENGTH = 39
MAX_PARSEABLE_INPUT_LENGTH = 40
MAX_OUTPUT_WORDS = 7
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
MAX_WORKSPACE_BYTES = 4096
WORKSPACE_BYTES = MAX_WORKSPACE_BYTES
SYMBOL = "junta_test_partition_binary_search"


def _decode(values: Sequence[int]) -> tuple[int, list[int], list[int], list[tuple[int, int]]] | None:
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, part_count, table_word_count = values[:3]
    if not 1 <= n <= MAX_N or not 1 <= part_count <= n:
        return None
    expected_table_words = ((1 << n) + 63) // 64
    if table_word_count != expected_table_words:
        return None
    table_start = 3
    table_end = table_start + expected_table_words
    labels_end = table_end + n
    expected_length = labels_end + ROUNDS
    if len(values) != expected_length:
        return None
    table = [value & ((1 << 64) - 1) for value in values[table_start:table_end]]
    tail_bits = (1 << n) % 64
    if tail_bits and table[-1] >> tail_bits:
        return None
    labels = list(values[table_end:labels_end])
    if any(label < 0 or label >= part_count for label in labels):
        return None
    if set(labels) != set(range(part_count)):
        return None
    tape: list[tuple[int, int]] = []
    point_limit = 1 << n
    for at in range(labels_end, expected_length):
        pair = values[at]
        if not 0 <= pair < (1 << (2 * n)):
            return None
        x, y = pair & (point_limit - 1), pair >> n
        tape.append((x, y))
    return n, table, labels, tape


def _replay(decoded) -> list[int]:
    n, table, labels, tape = decoded
    part_masks = [0] * (max(labels) + 1)
    for coordinate, part in enumerate(labels):
        part_masks[part] |= 1 << coordinate

    active = (1 << n) - 1
    found: list[tuple[int, int]] = []
    query_count = 0

    def evaluate(point: int) -> int:
        return (table[point // 64] >> (point % 64)) & 1

    for round_index, (x, y) in enumerate(tape):
        hybrid = (x & ~active) | (y & active)
        x_value = evaluate(x)
        hybrid_value = evaluate(hybrid)
        query_count += 2
        if x_value == hybrid_value:
            continue

        # The endpoints differ only on active coordinates and have unequal
        # function values. Narrow their differing part set by one hybrid query.
        left_endpoint = x
        right_endpoint = hybrid
        left_value = x_value
        candidates = [part for part, mask in enumerate(part_masks) if active & mask]
        while len(candidates) > 1:
            cut = len(candidates) // 2
            left_parts = candidates[:cut]
            left_mask = 0
            for part in left_parts:
                left_mask |= part_masks[part]
            probe = (left_endpoint & ~left_mask) | (right_endpoint & left_mask)
            probe_value = evaluate(probe)
            query_count += 1
            if probe_value != left_value:
                right_endpoint = probe
                candidates = left_parts
            else:
                left_endpoint = probe
                left_value = probe_value
                candidates = candidates[cut:]

        selected = candidates[0]
        active &= ~part_masks[selected]
        found.append((round_index, selected))
        if len(found) > K:
            words = [1, len(found), query_count]
            for found_round, part in found:
                words.extend((found_round, part))
            return words

    words = [0, len(found), query_count]
    for found_round, part in found:
        words.extend((found_round, part))
    return words


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    words = _replay(decoded)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
