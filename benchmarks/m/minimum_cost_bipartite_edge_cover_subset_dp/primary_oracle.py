"""Row-subset dynamic program for a bounded weighted bipartite edge cover."""

from __future__ import annotations

MAX_LEFT = 8
MAX_RIGHT = 8
MAX_COST = 1000
MAX_VALID_INPUT_LENGTH = 66
MAX_PARSEABLE_INPUT_LENGTH = 67
WORKSPACE_BYTES = 8192
INF = 1 << 60


def _parse(values: list[int] | tuple[int, ...] | None,
           input_is_null: bool, input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    left_count, right_count = values[:2]
    if not 1 <= left_count <= MAX_LEFT or not 1 <= right_count <= MAX_RIGHT:
        return None
    if len(values) != 2 + left_count * right_count:
        return None
    if any(cost < 0 or cost > MAX_COST for cost in values[2:]):
        return None
    return left_count, right_count


def expected_result(values: list[int] | tuple[int, ...] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return minimum edge-cover cost or -1 for a malformed frame."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    left_count, right_count = parsed
    assert values is not None
    states = 1 << right_count
    costs = values[2:]
    current = [INF] * states
    current[0] = 0

    for left in range(left_count):
        subset_cost = [0] * states
        for subset in range(1, states):
            bit = subset & -subset
            right = bit.bit_length() - 1
            subset_cost[subset] = subset_cost[subset ^ bit] + costs[left * right_count + right]
        following = [INF] * states
        for covered, prefix_cost in enumerate(current):
            if prefix_cost == INF:
                continue
            for selected in range(1, states):
                combined = covered | selected
                candidate = prefix_cost + subset_cost[selected]
                if candidate < following[combined]:
                    following[combined] = candidate
        current = following
    return current[-1]
