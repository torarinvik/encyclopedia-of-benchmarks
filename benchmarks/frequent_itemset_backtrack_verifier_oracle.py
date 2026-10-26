"""Independent subset-support model for the bounded Backtrack profile."""

MAX_INPUT_LENGTH = 19
MAX_OUTPUT_BYTES = 4088


def verify(values):
    if values is None or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    item_count, row_count, threshold = values[0], values[1], values[2]
    if not 1 <= item_count <= 8 or not 1 <= row_count <= 16:
        return -1, b""
    if not 1 <= threshold <= row_count or len(values) != row_count + 3:
        return -1, b""
    tx = values[3:]
    if any(mask < 0 or mask >= (1 << item_count) for mask in tx):
        return -1, b""

    found = []
    # Exhaustively inspect subsets; sorting tuples gives the documented
    # prefix-first itemset order without using the recursive source traversal.
    for mask in range(1, 1 << item_count):
        support = sum(1 for row in tx if row & mask == mask)
        if support >= threshold:
            items = tuple(i for i in range(item_count) if mask & (1 << i))
            found.append((items, mask, support))
    found.sort(key=lambda entry: entry[0])
    words = [len(found)]
    for _, mask, support in found:
        words.extend((mask, support))
    raw = b"".join(int(word).to_bytes(8, "little", signed=True) for word in words)
    return len(raw), raw
