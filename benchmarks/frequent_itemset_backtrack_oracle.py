"""Tail-extension / down-projection oracle for Chapter 722's Backtrack method."""

MAX_INPUT_LENGTH = 19
MAX_OUTPUT_BYTES = 4088


def evaluate(values):
    if values is None or len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, transaction_count, minimum_support = values[:3]
    if not 1 <= n <= 8 or not 1 <= transaction_count <= 16:
        return -1, b""
    if not 1 <= minimum_support <= transaction_count or len(values) != 3 + transaction_count:
        return -1, b""
    limit = 1 << n
    transactions = values[3:]
    if any(mask < 0 or mask >= limit for mask in transactions):
        return -1, b""

    records = []

    def visit(projected, start_item, prefix_mask):
        for item in range(start_item, n):
            bit = 1 << item
            child_rows = [row for row in projected if row & bit]
            if len(child_rows) < minimum_support:
                continue
            child_mask = prefix_mask | bit
            records.append((child_mask, len(child_rows)))
            visit(child_rows, item + 1, child_mask)

    visit(transactions, 0, 0)
    words = [len(records)]
    for mask, support in records:
        words.extend((mask, support))
    raw = b"".join(int(word).to_bytes(8, "little", signed=True) for word in words)
    return len(raw), raw
