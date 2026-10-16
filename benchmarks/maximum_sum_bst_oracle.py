"""Oracle for the pinned Python maximum-sum-BST traversal."""

from __future__ import annotations

MAX_SLOTS = 31
MAX_VALUE = 1_000_000
MAX_INPUT_LENGTH = MAX_SLOTS + 1
INVALID_RESULT = -1

def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    count = values[0]
    if not 0 <= count <= MAX_SLOTS or len(values) != count + 1:
        return INVALID_RESULT
    slots = values[1:]
    for i, value in enumerate(slots):
        if value != -1 and not 0 <= value <= MAX_VALUE:
            return INVALID_RESULT
        if value != -1 and i > 0 and slots[(i - 1) // 2] == -1:
            return INVALID_RESULT
    if count == 0:
        return 0
    valid = [False] * count
    minimum = [0] * count
    maximum = [0] * count
    total = [0] * count
    best = [0] * count
    for i in range(count - 1, -1, -1):
        value = slots[i]
        if value == -1:
            valid[i], minimum[i], maximum[i] = True, MAX_VALUE + 1, -1
            continue
        left, right = 2 * i + 1, 2 * i + 2
        left_valid = left >= count or valid[left]
        right_valid = right >= count or valid[right]
        left_min = minimum[left] if left < count else MAX_VALUE + 1
        left_max = maximum[left] if left < count else -1
        right_min = minimum[right] if right < count else MAX_VALUE + 1
        right_max = maximum[right] if right < count else -1
        left_sum = total[left] if left < count else 0
        right_sum = total[right] if right < count else 0
        left_best = best[left] if left < count else 0
        right_best = best[right] if right < count else 0
        if left_valid and right_valid and left_max < value < right_min:
            valid[i] = True
            minimum[i] = min(left_min, value)
            maximum[i] = max(right_max, value)
            total[i] = left_sum + right_sum + value
            best[i] = max(total[i], left_best, right_best)
        else:
            best[i] = max(left_best, right_best)
    return best[0]
