"""Monotone-queue oracle for bounded-multiplicity knapsack."""

from __future__ import annotations

MAX_CAPACITY = 64
MAX_TYPES = 16
MAX_WEIGHT = 16
MAX_VALUE = 100
MAX_COUNT = 16
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_TYPES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
INVALID_RESULT = -1
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def expected_result(values: list[int]) -> int:
    """Return the best bounded-knapsack value, or -1 for a malformed frame."""
    if (not isinstance(values, list)
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT
    capacity, type_count = values[:2]
    if not 0 <= capacity <= MAX_CAPACITY or not 0 <= type_count <= MAX_TYPES:
        return INVALID_RESULT
    if len(values) != 2 + 3 * type_count:
        return INVALID_RESULT

    dp = [0] * (capacity + 1)
    for item in range(type_count):
        weight, value, count = values[2 + 3 * item:5 + 3 * item]
        if not 1 <= weight <= MAX_WEIGHT or not 0 <= value <= MAX_VALUE or not 0 <= count <= MAX_COUNT:
            return INVALID_RESULT

        next_dp = [0] * (capacity + 1)
        for residue in range(min(weight, capacity + 1)):
            queue_index = [0] * (capacity + 1)
            queue_score = [0] * (capacity + 1)
            head = 0
            tail = 0
            max_t = (capacity - residue) // weight
            for t in range(max_t + 1):
                current_capacity = residue + t * weight
                score = dp[current_capacity] - t * value
                while tail > head and queue_score[tail - 1] <= score:
                    tail -= 1
                queue_index[tail] = t
                queue_score[tail] = score
                tail += 1

                first_allowed = max(0, t - count)
                while head < tail and queue_index[head] < first_allowed:
                    head += 1
                next_dp[current_capacity] = t * value + queue_score[head]
        dp = next_dp
    return dp[capacity]
