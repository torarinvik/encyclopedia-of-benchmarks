"""Independent oracle for bounded linked-list two-pointer operations."""

from __future__ import annotations

MAX_NODES = 128
MIN_I64 = -(1 << 63)
MAX_I64 = (1 << 63) - 1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 4
            or len(values) > 4 + MAX_NODES
            or any(type(value) is not int or not MIN_I64 <= value <= MAX_I64
                   for value in values)):
        return -1
    op, n, cycle_target, k = values[:4]
    if not 0 <= n <= MAX_NODES or len(values) != 4 + n:
        return -1
    nodes = values[4:]
    if any(not -1_000_000 <= value <= 1_000_000 for value in nodes):
        return -1
    if n == 0:
        if cycle_target != -1:
            return -1
    elif cycle_target < -1 or cycle_target >= n:
        return -1

    def next_node(index: int) -> int:
        if index < 0:
            return -1
        return index + 1 if index + 1 < n else cycle_target

    if op == 0:
        if k != 0:
            return -1
        slow = fast = 0 if n else -1
        while fast != -1:
            slow = next_node(slow)
            fast = next_node(fast)
            if fast != -1:
                fast = next_node(fast)
            if slow == -1 or fast == -1:
                break
            if slow == fast:
                return 1
        return 0

    if op == 1:
        if cycle_target != -1 or k != 0:
            return -1
        if n == 0:
            return -2
        slow = fast = 0
        while fast != -1:
            fast = next_node(fast)
            if fast == -1:
                break
            fast = next_node(fast)
            slow = next_node(slow)
        return nodes[slow] + 1_000_001

    if op == 2:
        if cycle_target != -1:
            return -1
        if k < 1 or k > n:
            return -1
        lead = lag = 0
        for _ in range(k):
            lead = next_node(lead)
        while lead != -1:
            lead = next_node(lead)
            lag = next_node(lag)
        return nodes[lag] + 3_000_002

    return -1
