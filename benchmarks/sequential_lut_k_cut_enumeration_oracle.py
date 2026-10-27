"""Primary set-valued oracle for the bounded DAG K-cut recurrence."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from itertools import product

MAX_INPUT_LENGTH = 12
MAX_OUTPUT_BYTES = 1112


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or
            capacity is not None and (type(capacity) is not int or capacity < 0) or
            input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values): return -1, b""
    if not 3 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values): return -1, b""
    n, k, m = values[:3]
    if not 1 <= n <= 3 or not 1 <= k <= 2 or not 0 <= m <= 3 or len(values) != 3 + 3*m: return -1, b""
    edges: list[tuple[int,int,int]] = []
    for i in range(m):
        u,v,d=values[3+3*i:6+3*i]
        if not (0 <= u < v < n) or d not in (0,1) or (u,v,d) in edges: return -1, b""
        edges.append((u,v,d))
    cuts: list[list[int]] = [[1 << (3*v)] for v in range(n)]
    for v in range(n):
        incoming=[e for e in edges if e[1]==v]
        choices=[]
        for u,_,delay in incoming:
            shifted=[]
            for mask in cuts[u]:
                out=0
                for bit in range(3*n):
                    if mask & (1<<bit):
                        node,old_delay=divmod(bit,3)
                        new_delay=old_delay+delay
                        if new_delay>2: return -1
                        out |= 1 << (3*node+new_delay)
                shifted.append(out)
            choices.append(shifted)
        if choices:
            for selection in product(*choices):
                merged=0
                for mask in selection: merged |= mask
                if merged.bit_count() <= k: cuts[v].append(merged)
        cuts[v]=sorted(set(cuts[v]))
    words=[n]
    for row in cuts: words.append(len(row));words.extend(row)
    size=8*len(words)
    if output_is_null or capacity is not None and capacity<size: return -2,b""
    return size,b"".join(struct.pack("<q",x) for x in words)
