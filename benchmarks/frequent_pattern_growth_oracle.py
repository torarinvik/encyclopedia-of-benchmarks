"""Independent exhaustive oracle for bounded frequent-itemset counts."""

from __future__ import annotations

MAX_TRANSACTIONS = 64
MAX_ITEMS = 8
MAX_INPUT_LENGTH = 3 + MAX_TRANSACTIONS


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    transaction_count, item_count, minimum_support = values[:3]
    if (not 1 <= transaction_count <= MAX_TRANSACTIONS
            or not 1 <= item_count <= MAX_ITEMS
            or not 1 <= minimum_support <= transaction_count
            or len(values) != 3 + transaction_count):
        return -1
    limit = 1 << item_count
    transactions = values[3:]
    if any(mask < 0 or mask >= limit for mask in transactions):
        return -1
    frequent = 0
    for itemset in range(1, limit):
        support = sum((transaction & itemset) == itemset for transaction in transactions)
        frequent += support >= minimum_support
    return frequent
