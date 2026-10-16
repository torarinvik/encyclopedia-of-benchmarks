"""Oracle for the pinned Haskell powerset ordering."""

MAX_INPUT_LENGTH = 7
MAX_COUNT = 6
MAX_OUTPUT_BYTES = 1602


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1, b""
    count = values[0]
    if not 0 <= count <= MAX_COUNT or len(values) != count + 1:
        return -1, b""
    items = values[1:]
    if any(not -(2**31) <= value < 2**31 for value in items):
        return -1, b""
    subsets = []

    def generate(index, selected):
        if index == count:
            subsets.append(selected)
            return
        generate(index + 1, selected)
        generate(index + 1, selected + [items[index]])

    generate(0, [])
    result = bytearray(len(subsets).to_bytes(2, "little"))
    for subset in subsets:
        result.append(len(subset))
        for value in subset:
            result.extend(value.to_bytes(8, "little", signed=True))
    return len(result), bytes(result)
