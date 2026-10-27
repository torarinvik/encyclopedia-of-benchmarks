"""Primary byte-output oracle for the bounded Extended-GS allocation profile."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_MEN = 2
MAX_WOMEN = 2
MAX_INPUT = 19
MAX_OUTPUT_BYTES = 104
INFINITY = 255


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    men, women, quota = values[:3]
    if not 1 <= men <= MAX_MEN or not 1 <= women <= MAX_WOMEN or not 1 <= quota <= 2:
        return None
    edge_count = men * women
    if len(values) != 3 + 4 * edge_count:
        return None
    male_marginal: list[tuple[int, int]] = []
    female_marginal: list[tuple[int, int]] = []
    for edge in range(edge_count):
        m_first, m_second, w_first, w_second = values[3 + 4 * edge:7 + 4 * edge]
        if (not 0 <= m_first <= 8 or not 0 <= m_second <= m_first
                or not 0 <= w_first <= 8 or not 0 <= w_second <= w_first):
            return None
        male_marginal.append((m_first, m_second))
        female_marginal.append((w_first, w_second))
    return men, women, quota, male_marginal, female_marginal


def _utility(marginal: tuple[int, int], count: int) -> int:
    if count == 0:
        return 0
    if count == 1:
        return marginal[0]
    return marginal[0] + marginal[1]


def _best_men(decoded, x_w: list[int], z_m: list[int]) -> list[int]:
    men, women, quota, male_marginal, _ = decoded
    edge_count = men * women
    best: tuple[int, ...] | None = None
    best_value = -1
    for candidate in itertools.product(range(3), repeat=edge_count):
        feasible = True
        for edge, count in enumerate(candidate):
            if count < x_w[edge] or count > z_m[edge]:
                feasible = False
                break
        if not feasible:
            continue
        if any(sum(candidate[i * women:(i + 1) * women]) > quota for i in range(men)):
            continue
        value = sum(_utility(male_marginal[e], count) for e, count in enumerate(candidate))
        if value > best_value:
            best, best_value = candidate, value
    assert best is not None
    return list(best)


def _best_women(decoded, x_m: list[int]) -> list[int]:
    men, women, quota, _, female_marginal = decoded
    edge_count = men * women
    best: tuple[int, ...] | None = None
    best_value = -1
    for candidate in itertools.product(range(3), repeat=edge_count):
        if any(candidate[e] > x_m[e] for e in range(edge_count)):
            continue
        if any(sum(candidate[i * women + j] for i in range(men)) > quota for j in range(women)):
            continue
        value = sum(_utility(female_marginal[e], count) for e, count in enumerate(candidate))
        if value > best_value:
            best, best_value = candidate, value
    assert best is not None
    return list(best)


def _solve(decoded) -> list[int]:
    men, women, _, _, _ = decoded
    edge_count = men * women
    x_w = [0] * edge_count
    z_m = [INFINITY] * edge_count
    z_w = [0] * edge_count
    for _ in range(3 * edge_count + 2):
        x_m = _best_men(decoded, x_w, z_m)
        x_w = _best_women(decoded, x_m)
        if x_m == x_w:
            return [edge_count, *x_m, *z_m, *(max(z_w[e], x_m[e]) for e in range(edge_count))]
        for edge in range(edge_count):
            if x_m[edge] > x_w[edge]:
                z_m[edge] = x_w[edge]
                z_w[edge] = INFINITY
    raise AssertionError("Extended-GS failed to converge within its bounded state space")


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    payload = struct.pack("<" + "q" * (1 + 3 * decoded[0] * decoded[1]), *_solve(decoded))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
