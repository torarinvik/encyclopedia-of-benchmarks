"""Independent exhaustive-coloring verifier for the dense-model tester."""

from __future__ import annotations

from collections.abc import Sequence

MASK64 = (1 << 64) - 1


def _read(values, input_is_null: bool, input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 4
            or len(values) > 82
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= 64 or not 1 <= q <= 16 or q > n or len(values) != 2 + n + q:
        return None
    rows = values[2:2 + n]
    for vertex, row in enumerate(rows):
        bits = row & MASK64
        if n < 64 and (row < 0 or bits >> n):
            return None
        if (bits >> vertex) & 1:
            return None
        for other in range(vertex):
            if ((bits >> other) & 1) != (((rows[other] & MASK64) >> vertex) & 1):
                return None
    draws = values[2 + n:]
    if any(draw < 0 or draw >= n - index for index, draw in enumerate(draws)):
        return None
    return n, q, rows, draws


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, q, rows, draws = parsed
    remaining = list(range(n))
    sample = []
    for i, draw in enumerate(draws):
        selected = i + draw
        remaining[i], remaining[selected] = remaining[selected], remaining[i]
        sample.append(remaining[i])
    edges = []
    for i in range(q):
        row = rows[sample[i]] & MASK64
        for j in range(i + 1, q):
            if (row >> sample[j]) & 1:
                edges.append((i, j))

    accepted = 0
    for coloring in range(1 << q):
        if all(((coloring >> left) ^ (coloring >> right)) & 1 for left, right in edges):
            accepted = 1
            break
    payload = accepted.to_bytes(8, "little", signed=True) + (q * (q - 1) // 2).to_bytes(8, "little", signed=True)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
