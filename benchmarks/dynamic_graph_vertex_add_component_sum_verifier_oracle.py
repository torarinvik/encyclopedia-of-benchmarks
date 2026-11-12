"""Independent rebuild-per-query oracle for dynamic component sums."""

import struct
from typing import Sequence

MAX_N = 16
MAX_Q = 32
MAX_VALUE = 100
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_Q * 8


def _sum_with_rebuilt_dsu(n: int, weights: list[int],
                          edges: set[tuple[int, int]], vertex: int) -> int:
    parent = list(range(n))
    size = [1] * n
    totals = list(weights)

    def find(x: int) -> int:
        while parent[x] != x:
            x = parent[x]
        return x

    for u, v in edges:
        ru, rv = find(u), find(v)
        if ru == rv:
            continue
        if size[ru] < size[rv] or (size[ru] == size[rv] and ru > rv):
            ru, rv = rv, ru
        parent[rv] = ru
        size[ru] += size[rv]
        totals[ru] += totals[rv]
    return totals[find(vertex)]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return -1, b""
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + n + 3 * q:
        return -1, b""
    weights = list(values[2:2 + n])
    if any(not 0 <= x <= MAX_VALUE for x in weights):
        return -1, b""

    active: set[tuple[int, int]] = set()
    answers: list[int] = []
    for offset in range(2 + n, len(values), 3):
        op, a, b = values[offset:offset + 3]
        if op == 0 or op == 1:
            if not 0 <= a < n or not 0 <= b < n or a == b:
                return -1, b""
            edge = (min(a, b), max(a, b))
            if op == 0:
                if edge in active:
                    return -1, b""
                active.add(edge)
            else:
                if edge not in active:
                    return -1, b""
                active.remove(edge)
        elif op == 2:
            if not 0 <= a < n or not 0 <= b <= MAX_VALUE:
                return -1, b""
            weights[a] += b
        elif op == 3:
            if not 0 <= a < n or b != 0:
                return -1, b""
            answers.append(_sum_with_rebuilt_dsu(n, weights, active, a))
        else:
            return -1, b""

    required = 8 * len(answers)
    cap = MAX_OUTPUT_BYTES if capacity is None else capacity
    if type(output_is_null) is not bool or type(cap) is not int or cap < 0:
        return -2, b""
    if output_is_null or cap < required:
        return -2, b""
    payload = b"".join(struct.pack("<q", x) for x in answers)
    return len(payload), payload
