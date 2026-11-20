"""Exhaustive closed-mask classification with parent reconstruction."""

MAX_ITEMS = 8
MAX_ROWS = 16
MAX_INPUT_LENGTH = 3 + MAX_ROWS
MAX_OUTPUT_BYTES = 8 * (1 + 2 * (1 << MAX_ITEMS))
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _encode(words):
    return b"".join(int(word).to_bytes(8, "little", signed=True) for word in words)


def verify(values):
    if (not isinstance(values, (tuple, list)) or len(values) < 4
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    item_count, row_count, threshold = values[:3]
    if not 1 <= item_count <= MAX_ITEMS or not 1 <= row_count <= MAX_ROWS:
        return -1, b""
    if not 1 <= threshold <= row_count or len(values) != 3 + row_count:
        return -1, b""
    rows = values[3:]
    limit = 1 << item_count
    if any(row < 0 or row >= limit for row in rows):
        return -1, b""

    def support(mask):
        return sum(1 for row in rows if row & mask == mask)

    def closure(mask):
        common = limit - 1
        found = False
        for row in rows:
            if row & mask == mask:
                common &= row
                found = True
        return common if found else None

    closed_support = {}
    for mask in range(limit):
        count = support(mask)
        if count < threshold:
            continue
        if closure(mask) == mask:
            closed_support[mask] = count

    root = closure(0)
    children = {mask: [] for mask in closed_support}
    for mask, count in closed_support.items():
        if mask == root:
            continue
        core = next(
            item for item in range(item_count)
            if support(mask & ((1 << (item + 1)) - 1)) == count
        )
        parent = closure(mask & ((1 << core) - 1))
        children[parent].append((core, mask))
    for descendants in children.values():
        descendants.sort()

    records = []

    def visit(mask):
        records.append((mask, closed_support[mask]))
        for _, child in children[mask]:
            visit(child)

    visit(root)
    words = [len(records)]
    for mask, count in records:
        words.extend((mask, count))
    raw = _encode(words)
    return len(raw), raw


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Apply the byte-output ABI around exhaustive closed-mask classification."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    result, output = verify(values)
    if result < 0:
        return result, b""
    if output_is_null or capacity is not None and capacity < result:
        return -2, b""
    return result, output
