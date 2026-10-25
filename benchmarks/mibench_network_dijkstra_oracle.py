"""Independent FIFO label-correcting oracle for bounded MiBench network-Dijkstra."""

from __future__ import annotations

from collections import deque

MAX_NODES = 6
MAX_INPUT_LENGTH = 2 + MAX_NODES * MAX_NODES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_EDGE_COST = 31
NONE = 9999
MAX_QUEUE_ITEMS = 1024
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
QUEUE_LIMIT_RESULT = -2


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 3:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    node_count, source = values[0], values[1]
    if not 1 <= node_count <= MAX_NODES or len(values) != 2 + node_count * node_count:
        return INVALID_RESULT
    if not 0 <= source < node_count:
        return INVALID_RESULT
    costs = values[2:]
    if any(cost != NONE and not 0 <= cost <= MAX_EDGE_COST for cost in costs):
        return INVALID_RESULT

    distances = [NONE] * node_count
    reached = [False] * node_count
    distances[source] = 0
    reached[source] = True
    queue: deque[tuple[int, int, int]] = deque([(source, 0, -1)])
    enqueued = 1
    while queue:
        node, queued_distance, _previous = queue.popleft()
        row = node * node_count
        for destination in range(node_count):
            cost = costs[row + destination]
            if cost == NONE:
                continue
            candidate = queued_distance + cost
            if not reached[destination] or distances[destination] > candidate:
                distances[destination] = candidate
                reached[destination] = True
                queue.append((destination, candidate, node))
                enqueued += 1
                if enqueued > MAX_QUEUE_ITEMS:
                    return QUEUE_LIMIT_RESULT

    checksum = 0
    reachable_mask = 0
    for node, is_reached in enumerate(reached):
        if is_reached:
            checksum += (node + 1) * distances[node]
            reachable_mask |= 1 << node
    return checksum + reachable_mask
