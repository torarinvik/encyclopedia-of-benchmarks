"""Coordinate-list reference for deterministic partition-junta replay."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
K = 1
ROUNDS = 24
MAX_VALID_INPUT_LENGTH = 39
MAX_PARSEABLE_INPUT_LENGTH = 40
MAX_OUTPUT_WORDS = 7
MAX_OUTPUT_BYTES = 56
MAX_WORKSPACE_BYTES = 4096
WORKSPACE_BYTES = MAX_WORKSPACE_BYTES


def _read(values: Sequence[int]):
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(v) is not int or v < -(1 << 63) or v >= (1 << 63) for v in values):
        return None
    n, parts = values[0], values[1]
    if n < 1 or n > MAX_N or parts < 1 or parts > n:
        return None
    count = 1 << n
    expected_words = (count + 63) // 64
    if values[2] != expected_words:
        return None
    table_at = 3
    tape_at = table_at + expected_words + n
    if len(values) != tape_at + ROUNDS:
        return None
    packed = [v & ((1 << 64) - 1) for v in values[table_at : table_at + expected_words]]
    tail_bits = count % 64
    if tail_bits and packed[-1] >> tail_bits:
        return None
    table = [(packed[index // 64] >> (index % 64)) & 1 for index in range(count)]
    assignment = list(values[table_at + expected_words : tape_at])
    if any(v < 0 or v >= parts for v in assignment) or set(assignment) != set(range(parts)):
        return None
    points = []
    for j in range(ROUNDS):
        packed_pair = values[tape_at + j]
        if packed_pair < 0 or packed_pair >= (1 << (2 * n)):
            return None
        points.append((packed_pair & (count - 1), packed_pair >> n))
    return n, table, assignment, points


def _table_walk(decoded) -> list[int]:
    n, table, assignment, points = decoded
    groups = [[i for i, label in enumerate(assignment) if label == part] for part in range(max(assignment) + 1)]
    remaining = set(range(n))
    discoveries: list[tuple[int, int]] = []
    queries = 0

    def evaluate(bits: list[int]) -> int:
        nonlocal queries
        queries += 1
        index = sum(bit << coordinate for coordinate, bit in enumerate(bits))
        return table[index]

    for round_index in range(ROUNDS):
        x_mask, y_mask = points[round_index]
        x = [(x_mask >> i) & 1 for i in range(n)]
        y = [(y_mask >> i) & 1 for i in range(n)]
        mixed = [y[i] if i in remaining else x[i] for i in range(n)]
        left_value = evaluate(x)
        right_value = evaluate(mixed)
        if left_value == right_value:
            continue

        active_groups = [group_id for group_id, group in enumerate(groups) if any(i in remaining for i in group)]
        # Keep two explicit assignments with different outputs. A probe takes
        # the right endpoint on the lower half and the left endpoint elsewhere.
        left_bits, right_bits = x, mixed
        left_observed = left_value
        while len(active_groups) > 1:
            midpoint = len(active_groups) // 2
            low_groups = active_groups[:midpoint]
            low_coordinates = {i for group_id in low_groups for i in groups[group_id] if i in remaining}
            probe = [right_bits[i] if i in low_coordinates else left_bits[i] for i in range(n)]
            observed = evaluate(probe)
            if observed != left_observed:
                right_bits = probe
                active_groups = low_groups
            else:
                left_bits = probe
                left_observed = observed
                active_groups = active_groups[midpoint:]

        chosen = active_groups[0]
        for coordinate in groups[chosen]:
            remaining.discard(coordinate)
        discoveries.append((round_index, chosen))
        if len(discoveries) > K:
            words = [1, len(discoveries), queries]
            for event in discoveries:
                words.extend(event)
            return words

    words = [0, len(discoveries), queries]
    for event in discoveries:
        words.extend(event)
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
    if input_is_null or values is None or not isinstance(values, (tuple, list)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    decoded = _read(values)
    if decoded is None:
        return -1, b""
    words = _table_walk(decoded)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
