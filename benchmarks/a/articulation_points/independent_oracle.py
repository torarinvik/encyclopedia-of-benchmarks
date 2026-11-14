"""Cut vertices by component counting after vertex deletion.

This deliberately does not share the benchmark's DFS low-link algorithm.
"""

from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 4096
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, m = values[:2]
    if not 0 <= n <= 64 or not 0 <= m <= 2047 or len(values) != 2 + 2*m:
        return -1, b""
    if (type(output_is_null) is not bool or capacity is not None
            and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    neighbors = [set() for _ in range(n)]
    for offset in range(2, len(values), 2):
        left, right = values[offset:offset+2]
        if not 0 <= left < n or not 0 <= right < n:
            return -1, b""
        neighbors[left].add(right)
        neighbors[right].add(left)

    def components(removed: int) -> int:
        unseen = set(range(n))
        unseen.discard(removed)
        count = 0
        while unseen:
            count += 1
            start = unseen.pop()
            stack = [start]
            while stack:
                vertex = stack.pop()
                reached = neighbors[vertex] & unseen
                unseen.difference_update(reached)
                stack.extend(reached)
        return count

    baseline = components(-1)
    output = bytes(vertex for vertex in range(n) if components(vertex) > baseline)
    if output and (output_is_null or capacity is not None and capacity < len(output)):
        return -2, b""
    return len(output), output
