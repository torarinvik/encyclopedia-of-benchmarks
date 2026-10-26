"""Independent exact-rational verifier for the bounded CoSimRank pair."""

from __future__ import annotations

from fractions import Fraction
import struct

MAX_NODES = 8
MAX_EDGES = 24
MAX_ITERATIONS = 4
MAX_INPUT_LENGTH = 5 + 2 * MAX_EDGES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    if (not isinstance(values, (tuple, list)) or len(values) < 5
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""
    n, m, source_u, source_v, iterations = values[:5]
    if (not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES
            or not 0 <= source_u < n or not 0 <= source_v < n
            or not 1 <= iterations <= MAX_ITERATIONS
            or len(values) != 5 + 2 * m):
        return INVALID_RESULT, b""
    edges = []
    edge_set = set()
    outdegree = [0] * n
    for offset in range(5, len(values), 2):
        source, destination = values[offset:offset + 2]
        if (not 0 <= source < n or not 0 <= destination < n
                or source == destination or (source, destination) in edge_set):
            return INVALID_RESULT, b""
        edge_set.add((source, destination))
        edges.append((source, destination))
        outdegree[source] += 1
    if any(degree not in (0, 1, 2, 4) for degree in outdegree):
        return INVALID_RESULT, b""

    current_u = [Fraction(0) for _ in range(n)]
    current_v = [Fraction(0) for _ in range(n)]
    current_u[source_u] = Fraction(1)
    current_v[source_v] = Fraction(1)
    similarity = Fraction(1 if source_u == source_v else 0)
    for step in range(1, iterations + 1):
        next_u = [Fraction(0) for _ in range(n)]
        next_v = [Fraction(0) for _ in range(n)]
        for source, destination in edges:
            next_u[destination] += current_u[source] / outdegree[source]
            next_v[destination] += current_v[source] / outdegree[source]
        inner_product = sum((next_u[v] * next_v[v] for v in range(n)), Fraction(0))
        similarity += Fraction(1, 2 ** step) * inner_product
        current_u, current_v = next_u, next_v
    encoded = struct.pack("<d", float(similarity))
    if output_is_null or capacity is not None and capacity < 8:
        return OUTPUT_ERROR, b""
    return 8, encoded
