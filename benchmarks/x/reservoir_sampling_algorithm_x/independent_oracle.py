"""Direct tail-CDF scan for the finite-grid Algorithm X profile."""

import struct

MAX_DRAW = (1 << 32) - 1
GRID_DENOMINATOR = (1 << 32) + 1


def _product(start, count):
    answer = 1
    for index in range(count):
        answer *= start - index
    return answer


def _direct_skip(processed, k, limit, threshold):
    numerator = _product(processed, k)
    for skipped in range(limit + 1):
        denominator = _product(processed + skipped + 1, k)
        if numerator * GRID_DENOMINATOR <= threshold * denominator:
            return skipped
    return None


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
    if len(values) != 2 + n + 2 * (n - k):
        return -1, b""
    stream = values[2:2 + n]
    draws = values[2 + n:]
    if any(item < -1_000_000 or item > 1_000_000 for item in stream):
        return -1, b""
    if any(draw < 0 or draw > MAX_DRAW for draw in draws):
        return -1, b""
    if output_is_null or (capacity is not None and capacity < 8 * k):
        return -2, b""
    sample = list(stream[:k])
    processed = k
    attempt = 0
    while processed < n:
        if attempt >= n - k:
            break
        threshold, slot_draw = draws[2 * attempt:2 * attempt + 2]
        attempt += 1
        skipped = _direct_skip(processed, k, n - processed - 1, threshold + 1)
        if skipped is None:
            break
        sample[slot_draw % k] = stream[processed + skipped]
        processed += skipped + 1
    return 8 * k, b"".join(struct.pack("<q", item) for item in sample)
