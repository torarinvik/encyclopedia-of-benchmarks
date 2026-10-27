"""Independent Extended-GS verifier using per-person choice enumeration."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_INPUT = 19
MAX_OUTPUT_BYTES = 104
INF = 255


def _read(values: Sequence[int] | None):
    if values is None or not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT:
        return None
    if any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return None
    men, women, capacity = values[:3]
    if men not in (1, 2) or women not in (1, 2) or capacity not in (1, 2):
        return None
    edge_count = men * women
    if len(values) != 3 + 4 * edge_count:
        return None
    man_values = []
    woman_values = []
    for edge in range(edge_count):
        a, b, c, d = values[3 + 4 * edge:7 + 4 * edge]
        if a < 0 or a > 8 or b < 0 or b > a or c < 0 or c > 8 or d < 0 or d > c:
            return None
        man_values.append((a, b))
        woman_values.append((c, d))
    return men, women, capacity, man_values, woman_values


def _person_choice(edges: list[int], quota: int, marginal: list[tuple[int, int]],
                   lower: list[int], upper: list[int]) -> dict[int, int]:
    ranges = [range(lower[e], upper[e] + 1) for e in edges]
    best_tuple: tuple[int, ...] | None = None
    best_utility = -1
    for choice in itertools.product(*ranges):
        if sum(choice) > quota:
            continue
        utility = 0
        for edge, count in zip(edges, choice):
            if count:
                utility += marginal[edge][0]
            if count == 2:
                utility += marginal[edge][1]
        if utility > best_utility or utility == best_utility and (best_tuple is None or choice < best_tuple):
            best_tuple = choice
            best_utility = utility
    assert best_tuple is not None
    return dict(zip(edges, best_tuple))


def _men_choice(data, x_w: list[int], z_m: list[int]) -> list[int]:
    men, women, quota, values, _ = data
    answer = [0] * (men * women)
    for man in range(men):
        edges = [man * women + woman for woman in range(women)]
        choice = _person_choice(edges, quota, values, x_w, z_m)
        for edge, count in choice.items():
            answer[edge] = count
    return answer


def _women_choice(data, x_m: list[int]) -> list[int]:
    men, women, quota, _, values = data
    answer = [0] * (men * women)
    for woman in range(women):
        edges = [man * women + woman for man in range(men)]
        choice = _person_choice(edges, quota, values, [0] * len(answer), x_m)
        for edge, count in choice.items():
            answer[edge] = count
    return answer


def _trace(data) -> list[int]:
    men, women, _, _, _ = data
    edge_count = men * women
    x_w = [0] * edge_count
    z_m = [INF] * edge_count
    z_w = [0] * edge_count
    for _ in range(3 * edge_count + 2):
        x_m = _men_choice(data, x_w, z_m)
        x_w = _women_choice(data, x_m)
        if x_m == x_w:
            return [edge_count, *x_m, *z_m, *(max(z_w[e], x_m[e]) for e in range(edge_count))]
        for edge in range(edge_count):
            if x_m[edge] > x_w[edge]:
                z_m[edge] = x_w[edge]
                z_w[edge] = INF
    raise AssertionError("Extended-GS did not reach its stable state")


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
    data = _read(values)
    if data is None:
        return -1, b""
    payload = struct.pack("<" + "q" * (1 + 3 * data[0] * data[1]), *_trace(data))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
