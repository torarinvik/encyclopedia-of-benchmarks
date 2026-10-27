"""Primary interval-DP oracle for a bounded source-defined RNA MFE profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 12
TABLE_SIZE = 6 * 13 * 3
MAX_INPUT = 1 + MAX_N + TABLE_SIZE
MAX_OUTPUT_BYTES = 112
INF = 1 << 60
PAIR_TYPES = {(0, 3): 0, (3, 0): 1, (1, 2): 2, (2, 1): 3, (2, 3): 4, (3, 2): 5}


def _lex_mask_less(left: int, right: int, pair_count: int) -> bool:
    left_at = right_at = 0
    while True:
        while left_at < pair_count and not (left >> left_at) & 1:
            left_at += 1
        while right_at < pair_count and not (right >> right_at) & 1:
            right_at += 1
        if left_at == pair_count or right_at == pair_count:
            return left_at == pair_count and right_at != pair_count
        if left_at != right_at:
            return left_at < right_at
        left_at += 1
        right_at += 1


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or not 5 <= len(values) <= MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n = values[0]
    if not 4 <= n <= MAX_N or len(values) != 1 + n + TABLE_SIZE:
        return None
    bases = list(values[1:1 + n])
    table = list(values[1 + n:])
    if any(base not in range(4) for base in bases) or any(cost < -1000 or cost > 1000 for cost in table):
        return None
    return n, bases, table


def _solve(n: int, bases: list[int], table: list[int]) -> tuple[int, list[tuple[int, int]]]:
    pair_type = [[-1] * n for _ in range(n)]
    pair_id = [[-1] * n for _ in range(n)]
    pairs: list[tuple[int, int]] = []
    for i in range(n):
        for j in range(i + 4, n):
            kind = PAIR_TYPES.get((bases[i], bases[j]), -1)
            if kind >= 0:
                pair_type[i][j] = kind
                pair_id[i][j] = len(pairs)
                pairs.append((i, j))

    v_energy = [[INF] * n for _ in range(n)]
    v_mask = [[0] * n for _ in range(n)]

    def cost(kind: int, unpaired: int, children: int) -> int:
        return table[kind * 39 + unpaired * 3 + children]

    def better(candidate_energy: int, candidate_mask: int, best_energy: int, best_mask: int) -> bool:
        return (candidate_energy < best_energy
                or candidate_energy == best_energy
                and _lex_mask_less(candidate_mask, best_mask, len(pairs)))

    for span in range(4, n):
        for i in range(n - span):
            j = i + span
            kind = pair_type[i][j]
            if kind < 0:
                continue
            outer_mask = 1 << pair_id[i][j]
            best_energy, best_mask = INF, 0

            candidate = cost(kind, span - 1, 0)
            if better(candidate, outer_mask, best_energy, best_mask):
                best_energy, best_mask = candidate, outer_mask

            inside = [(a, b) for a, b in pairs if i < a and b < j]
            for a, b in inside:
                child_energy = v_energy[a][b]
                if child_energy == INF:
                    continue
                unpaired = (a - i - 1) + (j - b - 1)
                candidate = cost(kind, unpaired, 1) + child_energy
                candidate_mask = outer_mask | v_mask[a][b]
                if better(candidate, candidate_mask, best_energy, best_mask):
                    best_energy, best_mask = candidate, candidate_mask

            for a, b in inside:
                if v_energy[a][b] == INF:
                    continue
                for c, d in inside:
                    if b >= c or v_energy[c][d] == INF:
                        continue
                    unpaired = (a - i - 1) + (c - b - 1) + (j - d - 1)
                    candidate = cost(kind, unpaired, 2) + v_energy[a][b] + v_energy[c][d]
                    candidate_mask = outer_mask | v_mask[a][b] | v_mask[c][d]
                    if better(candidate, candidate_mask, best_energy, best_mask):
                        best_energy, best_mask = candidate, candidate_mask

            v_energy[i][j] = best_energy
            v_mask[i][j] = best_mask

    w_energy = [0] * n
    w_mask = [0] * n
    for j in range(n):
        best_energy = w_energy[j - 1] if j else 0
        best_mask = w_mask[j - 1] if j else 0
        for i in range(max(0, j - 3)):
            if pair_type[i][j] < 0 or v_energy[i][j] == INF:
                continue
            prefix_energy = w_energy[i - 1] if i else 0
            prefix_mask = w_mask[i - 1] if i else 0
            candidate_energy = prefix_energy + v_energy[i][j]
            candidate_mask = prefix_mask | v_mask[i][j]
            if better(candidate_energy, candidate_mask, best_energy, best_mask):
                best_energy, best_mask = candidate_energy, candidate_mask
        w_energy[j], w_mask[j] = best_energy, best_mask

    selected = [pair for index, pair in enumerate(pairs) if (w_mask[-1] >> index) & 1]
    return w_energy[-1], selected


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
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    n, bases, table = decoded
    energy, pairs = _solve(n, bases, table)
    fields = [energy, len(pairs)]
    for i, j in pairs:
        fields.extend((i, j))
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
