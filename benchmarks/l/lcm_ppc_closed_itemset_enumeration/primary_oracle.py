"""LCM prefix-preserving-closure DFS for bounded transaction masks."""

MAX_ITEMS = 8
MAX_ROWS = 16
MAX_INPUT_LENGTH = 3 + MAX_ROWS
MAX_OUTPUT_BYTES = 8 * (1 + 2 * (1 << MAX_ITEMS))
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _words_to_bytes(words):
    return b"".join(int(word).to_bytes(8, "little", signed=True) for word in words)


def evaluate(values):
    if (not isinstance(values, (tuple, list)) or len(values) < 4
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    item_count, row_count, minimum_support = values[:3]
    if not 1 <= item_count <= MAX_ITEMS or not 1 <= row_count <= MAX_ROWS:
        return -1, b""
    if not 1 <= minimum_support <= row_count or len(values) != 3 + row_count:
        return -1, b""
    rows = values[3:]
    limit = 1 << item_count
    if any(mask < 0 or mask >= limit for mask in rows):
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

    root = closure(0)
    records = []

    def core_index(mask, pattern_support):
        for item in range(item_count):
            prefix = mask & ((1 << (item + 1)) - 1)
            if support(prefix) == pattern_support:
                return item
        return item_count - 1

    def visit(mask, pattern_support, core):
        records.append((mask, pattern_support))
        for item in range(core + 1, item_count):
            bit = 1 << item
            if mask & bit:
                continue
            child = mask | bit
            child_support = support(child)
            if child_support < minimum_support:
                continue
            child_closure = closure(child)
            lower_prefix_mask = bit - 1
            if mask & lower_prefix_mask != child_closure & lower_prefix_mask:
                continue
            visit(child_closure, child_support, core_index(child_closure, child_support))

    visit(root, row_count, -1)
    words = [len(records)]
    for mask, pattern_support in records:
        words.extend((mask, pattern_support))
    raw = _words_to_bytes(words)
    return len(raw), raw


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Apply the i64-array byte-output ABI to the ppc traversal."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    result, output = evaluate(values)
    if result < 0:
        return result, b""
    if output_is_null or capacity is not None and capacity < result:
        return -2, b""
    return result, output
