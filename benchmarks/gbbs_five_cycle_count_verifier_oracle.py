"""Independent canonical-path verifier for the bounded five-cycle count."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
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
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return INVALID_RESULT, b""
    edges = set()
    for index in range(m):
        u, v = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= u < v < n or (u, v) in edges:
            return INVALID_RESULT, b""
        edges.add((u, v))

    # Each cycle is rooted at its minimum vertex; the smaller of its two
    # adjacent vertices is the first path endpoint. This canonical path scan
    # does not share the package oracle's combination/permutation method.
    count = 0
    for start in range(n):
        for first in range(start + 1, n):
            for second in range(start + 1, n):
                if second == first:
                    continue
                for third in range(start + 1, n):
                    if third == first or third == second:
                        continue
                    for last in range(first + 1, n):
                        if last == second or last == third:
                            continue
                        path = (start, first, second, third, last)
                        if all((min(path[i], path[(i + 1) % 5]),
                                max(path[i], path[(i + 1) % 5])) in edges
                               for i in range(5)):
                            count += 1
    encoded = struct.pack("<q", count)
    if output_is_null or capacity is not None and capacity < 8:
        return OUTPUT_ERROR, b""
    return 8, encoded
