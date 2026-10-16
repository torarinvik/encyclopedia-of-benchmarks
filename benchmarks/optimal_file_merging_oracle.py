"""Oracle for the bounded optimal pairwise file-merging cost."""

MAX_INPUT_LENGTH = 33


def expected_result(values: list[int]) -> int:
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return -1
    count = values[0]
    if not 0 <= count <= 32 or len(values) != count + 1:
        return -1
    files = values[1:].copy()
    if any(not 0 <= size <= 1_000_000 for size in files):
        return -1
    total = 0
    while len(files) > 1:
        files.sort()
        merged = files.pop(0) + files.pop(0)
        total += merged
        files.append(merged)
    return total
