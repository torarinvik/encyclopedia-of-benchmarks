"""Oracle for bounded balanced-parenthesis generation."""

MAX_INPUT_LENGTH = 1
MAX_PAIRS = 6
MAX_OUTPUT_BYTES = 1586


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_PAIRS):
        return -1, b""
    pairs = values[0]
    outputs = []

    def generate(open_count, close_count, current):
        if len(current) == pairs * 2:
            outputs.append(bytes(current))
            return
        if open_count < pairs:
            generate(open_count + 1, close_count, current + [40])
        if close_count < open_count:
            generate(open_count, close_count + 1, current + [41])

    generate(0, 0, [])
    encoded = bytearray((len(outputs) & 255, len(outputs) >> 8))
    for item in outputs:
        encoded.extend(item)
    return len(encoded), bytes(encoded)
