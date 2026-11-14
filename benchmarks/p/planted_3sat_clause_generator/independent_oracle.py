"""Planted clause reference using explicit lexicographic subset enumeration."""

from itertools import combinations
import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False,
                    input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 5 <= len(values) <= 83
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(v) is not int or v < -(1 << 63) or v >= 1 << 63 for v in values)):
        return -1, b""
    n, m = values[:2]
    if not 3 <= n <= 16 or not 0 <= m <= 32 or len(values) != 2+n+2*m:
        return -1, b""
    assignment = values[2:2+n]
    if any(bit not in (0, 1) for bit in assignment):
        return -1, b""
    triples = tuple(combinations(range(n), 3))
    literals = []
    for index in range(m):
        rank, mask = values[2+n+2*index:4+n+2*index]
        if not 0 <= rank < len(triples) or not 1 <= mask <= 7:
            return -1, b""
        for bit, variable in enumerate(triples[rank]):
            satisfies = (mask >> bit) & 1
            literal = variable+1
            literals.append(literal if assignment[variable] == satisfies else -literal)
    payload = struct.pack("<" + "q"*len(literals), *literals)
    if payload and (output_is_null or capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
