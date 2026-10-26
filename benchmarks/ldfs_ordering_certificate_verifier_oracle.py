"""Independent verifier oracle using timestamp-priority bit comparisons."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 10


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > MAX_INPUT or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    count, root = values[0], values[1]
    if not 1 <= count <= 8 or not 0 <= root < count or len(values) != count + 2:
        return -1, b""
    full = (1 << count) - 1
    graph = list(values[2:])
    if any(row < 0 or row & ~full or row & (1 << v) for v, row in enumerate(graph)):
        return -1, b""
    if any(((graph[u] >> v) & 1) != ((graph[v] >> u) & 1) for u in range(count) for v in range(count)):
        return -1, b""
    component = 1 << root
    for _ in range(count):
        enlarged = component
        for u in range(count):
            if component >> u & 1:
                enlarged |= graph[u]
        component = enlarged
    if component != full:
        return -1, b""

    sequence = [root]
    while len(sequence) != count:
        choice = -1
        for v in range(count):
            if v in sequence:
                continue
            if choice < 0:
                choice = v
                continue
            for priority in range(len(sequence) - 1, -1, -1):
                pivot = sequence[priority]
                left = (graph[v] >> pivot) & 1
                right = (graph[choice] >> pivot) & 1
                if left != right:
                    if left > right:
                        choice = v
                    break
                if priority == 0 and v < choice:
                    choice = v
        sequence.append(choice)

    cert = []
    for earlier in range(count):
        a = sequence[earlier]
        for middle in range(earlier + 1, count):
            b = sequence[middle]
            for later in range(middle + 1, count):
                c = sequence[later]
                if (graph[a] >> c) & 1 and not ((graph[a] >> b) & 1):
                    d_found = -1
                    for pos in range(earlier + 1, middle):
                        d = sequence[pos]
                        if (graph[d] >> b) & 1 and not ((graph[d] >> c) & 1):
                            d_found = d
                            break
                    cert.extend((a, b, c, d_found))
    fields = [count, *sequence, len(cert) // 4, *cert]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
