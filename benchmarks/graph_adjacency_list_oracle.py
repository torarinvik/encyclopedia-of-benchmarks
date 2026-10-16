"""Oracle for a bounded operation trace on the Python adjacency-list Graph ADT."""

from __future__ import annotations

import struct

MAX_VERTICES = 32
MAX_EDGES = 1024
MAX_OPERATIONS = 64
MAX_OUTPUT_BYTES = (1 + 64 + 1 + 32 * 35) * 8


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if not isinstance(values, (list, tuple)) or len(values) < 4 or any(type(x) is not int for x in values):
        return -1, b""
    directed, n = values[:2]
    if directed not in (0, 1) or not 0 <= n <= MAX_VERTICES or len(values) < 3 + n:
        return -1, b""
    vertices = list(values[2:2+n])
    if len(set(vertices)) != n or any(not 0 <= v < MAX_VERTICES for v in vertices):
        return -1, b""
    i = 2 + n
    ec = values[i]
    i += 1
    if not 0 <= ec <= MAX_EDGES or len(values) < i + 2 * ec + 1:
        return -1, b""
    adj = {v: [] for v in vertices}
    for _ in range(ec):
        a, b = values[i:i + 2]
        i += 2
        if a not in adj or b not in adj or b in adj[a]:
            return -1, b""
        adj[a].append(b)
        if not directed:
            adj[b].append(a)
    oc = values[i]
    i += 1
    if not 0 <= oc <= MAX_OPERATIONS or len(values) != i + 3 * oc:
        return -1, b""
    results = []
    for _ in range(oc):
        op, a, b = values[i:i + 3]
        i += 3
        if op == 0:  # add vertex
            if not 0 <= a < MAX_VERTICES or b != 0 or a in adj:
                return -1, b""
            adj[a] = []
            vertices.append(a)
            results.append(1)
        elif op == 1:  # remove vertex
            if a not in adj or b != 0:
                return -1, b""
            if directed:
                for row in adj.values():
                    if a in row:
                        row.remove(a)
            else:
                for neighbor in adj[a]:
                    if neighbor != a and a in adj[neighbor]:
                        adj[neighbor].remove(a)
            del adj[a]
            vertices.remove(a)
            results.append(1)
        elif op == 2:  # add edge
            if a not in adj or b not in adj or b in adj[a]:
                return -1, b""
            adj[a].append(b)
            if not directed:
                adj[b].append(a)
            results.append(1)
        elif op == 3:  # remove edge
            if a not in adj or b not in adj or b not in adj[a]:
                return -1, b""
            adj[a].remove(b)
            if not directed:
                adj[b].remove(a)
            results.append(1)
        elif op == 4:  # contains vertex
            if not 0 <= a < MAX_VERTICES or b != 0:
                return -1, b""
            results.append(int(a in adj))
        elif op == 5:  # contains edge
            if a not in adj or b not in adj:
                return -1, b""
            results.append(int(b in adj[a]))
        elif op == 6:  # clear
            if a != 0 or b != 0:
                return -1, b""
            vertices.clear()
            adj.clear()
            results.append(1)
        else:
            return -1, b""
    out = [oc, *results, len(vertices)]
    for v in vertices:
        out.extend((v, len(adj[v]), *adj[v]))
    data = struct.pack("<" + "q" * len(out), *out)
    return len(data), data
