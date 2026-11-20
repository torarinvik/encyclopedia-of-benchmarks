"""Algorithm X skip replay with an exact reduced-rational tail recurrence."""

import math
import struct

MAX_DRAW = (1 << 32) - 1
GRID_DENOMINATOR = (1 << 32) + 1
MAX_VALID_INPUT_LENGTH = 48
MAX_PARSEABLE_INPUT_LENGTH = 49
MAX_OUTPUT_BYTES = 64
WORKSPACE_BYTES = 64


def _falling(value, count):
    product = 1
    for offset in range(count):
        product *= value - offset
    return product


def _replay(n, k, stream, pairs):
    sample = list(stream[:k])
    processed = k
    pair_index = 0
    while processed < n:
        if pair_index >= n - k:
            break
        skip_draw, slot_draw = pairs[pair_index]
        pair_index += 1
        numerator = _falling(processed, k)
        denominator = _falling(processed + 1, k)
        selected_skip = None
        max_skip = n - processed - 1
        for skip in range(max_skip + 1):
            if numerator * GRID_DENOMINATOR <= (skip_draw + 1) * denominator:
                selected_skip = skip
                break
            if skip < max_skip:
                top = processed + skip + 1
                numerator *= top + 1 - k
                denominator *= top + 1
                divisor = math.gcd(numerator, denominator)
                numerator //= divisor
                denominator //= divisor
        if selected_skip is None:
            break
        selected_index = processed + selected_skip
        sample[slot_draw % k] = stream[selected_index]
        processed = selected_index + 1
    return sample


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if len(values) < 3 or len(values) > 49 or any(type(value) is not int for value in values):
        return -1, b""
    n, k = values[:2]
    if not (1 <= n <= 16 and k in (1, 2, 4, 8) and k <= n):
        return -1, b""
    expected_length = 2 + n + 2 * (n - k)
    if len(values) != expected_length:
        return -1, b""
    stream = values[2:2 + n]
    if any(value < -1_000_000 or value > 1_000_000 for value in stream):
        return -1, b""
    draw_values = values[2 + n:]
    if any(value < 0 or value > MAX_DRAW for value in draw_values):
        return -1, b""
    pairs = [(draw_values[i], draw_values[i + 1]) for i in range(0, len(draw_values), 2)]
    if output_is_null or (capacity is not None and capacity < 8 * k):
        return -2, b""
    sample = _replay(n, k, stream, pairs)
    return 8 * k, b"".join(struct.pack("<q", value) for value in sample)
