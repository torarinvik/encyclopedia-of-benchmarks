"""Independent bounded oracle for the 0/1 knapsack tabulation benchmark."""

from __future__ import annotations

MAX_CAPACITY = 512
MAX_ITEMS = 128
MAX_WEIGHT = 4096
MAX_VALUE = 1_000_000_000
MAX_INPUT_LENGTH = 2 + 2 * MAX_ITEMS
INVALID_RESULT = -1
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1

PINNED_SOURCE = {
    "repository": "TheAlgorithms/Java",
    "commit": "e43ec3897e48f23843972d02cd05a5bb1b6864a2",
    "path": "src/main/java/com/thealgorithms/dynamicprogramming/KnapsackZeroOneTabulation.java",
    "method": "compute",
    "url": "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/KnapsackZeroOneTabulation.java",
    "role": "algorithm",
}

CASE_IDS = frozenset({
    "classic_example", "no_items_zero_capacity", "no_items_positive_capacity",
    "zero_capacity_skips_positive_weights", "exact_capacity_fit", "all_items_too_heavy",
    "combination_beats_best_single", "item_is_not_reused", "input_order_permutation",
    "zero_value_item", "maximum_capacity", "maximum_value_and_out_of_capacity_item",
    "maximum_item_count", "null_input_pointer_with_positive_length",
})


def expected_result(values: list[int]) -> int:
    """Return the maximum 0/1 knapsack value, or -1 for an invalid packed array."""
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    capacity, item_count = values[:2]
    if not 0 <= capacity <= MAX_CAPACITY or not 0 <= item_count <= MAX_ITEMS:
        return INVALID_RESULT
    if len(values) != 2 + 2 * item_count:
        return INVALID_RESULT

    dp = [0] * (capacity + 1)
    for item in range(item_count):
        weight, value = values[2 + 2 * item:4 + 2 * item]
        if not 1 <= weight <= MAX_WEIGHT or not 0 <= value <= MAX_VALUE:
            return INVALID_RESULT
        for current_capacity in range(capacity, weight - 1, -1):
            dp[current_capacity] = max(
                dp[current_capacity], dp[current_capacity - weight] + value
            )
    return dp[capacity]
