"""Planted clause generation with lexicographic combinatorial unranking."""

import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False,
                    input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 5 <= len(values) <= 83
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1, b""
    n, m = values[:2]
    if not 3 <= n <= 16 or not 0 <= m <= 32 or len(values) != 2+n+2*m:
        return -1, b""
    assignment = values[2:2+n]
    if any(bit not in (0, 1) for bit in assignment):
        return -1, b""
    words = []
    choices = n*(n-1)*(n-2)//6
    for clause in range(m):
        rank, mask = values[2+n+2*clause:4+n+2*clause]
        if not 0 <= rank < choices or not 1 <= mask <= 7:
            return -1, b""
        triple = []
        previous = -1
        for position in range(3):
            for variable in range(previous+1, n-(2-position)):
                remaining = n-variable-1
                ways = remaining*(remaining-1)//2 if position == 0 else remaining if position == 1 else 1
                if rank < ways:
                    triple.append(variable)
                    previous = variable
                    break
                rank -= ways
        for position, variable in enumerate(triple):
            literal_true = (mask >> position) & 1
            positive = assignment[variable] == literal_true
            words.append(variable+1 if positive else -(variable+1))
    payload = struct.pack("<" + "q"*len(words), *words)
    if payload and (output_is_null or capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
