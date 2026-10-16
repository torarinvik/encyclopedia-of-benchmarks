"""Oracle for the bounded chunk-splitting append-only unrolled list."""
MAX_ITEMS = 1024
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
VALUE_OFFSET = 1_000_000
INVALID = -1

def expected_result(values: list[int]) -> int:
    if len(values) > MAX_ITEMS or any(v < MIN_VALUE or v > MAX_VALUE for v in values):
        return INVALID
    # A block holds four values. On overflow, the pinned implementation keeps
    # floor(count/2)+1 values and moves the remaining suffix plus new item.
    blocks: list[list[int]] = []
    for value in values:
        if not blocks:
            blocks.append([value])
        elif len(blocks[-1]) < 4:
            blocks[-1].append(value)
        else:
            old = blocks[-1]
            split = len(old) // 2 + 1
            moved = old[split:]
            del old[split:]
            blocks.append(moved + [value])
    flattened = [value for block in blocks for value in block]
    return sum((index + 1) * (value + VALUE_OFFSET) for index, value in enumerate(flattened))
