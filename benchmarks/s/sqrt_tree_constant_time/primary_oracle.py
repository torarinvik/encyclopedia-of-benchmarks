"""Power-of-two Sqrt Tree with constant-time static range-minimum queries."""

from __future__ import annotations

MAX_ITEMS = 64
MAX_QUERIES = 64
MAX_LEVELS = 4
VALUE_LIMIT = 1_000_000_000
INF = (1 << 63) - 1
INVALID_RESULT = -1
BAD_OUTPUT_RESULT = -2
MAX_VALID_INPUT_LENGTH = 194
MAX_PARSEABLE_INPUT_LENGTH = 195
MAX_OUTPUT_BYTES = 512
MAX_WORKSPACE_BYTES = 8192


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n, query_count = values[:2]
    if not 1 <= n <= MAX_ITEMS or not 0 <= query_count <= MAX_QUERIES:
        return None
    if len(values) != 2 + n + 2 * query_count:
        return None
    array = values[2:2 + n]
    if any(value < -VALUE_LIMIT or value > VALUE_LIMIT for value in array):
        return None
    queries = []
    for offset in range(2 + n, len(values), 2):
        left, right = values[offset:offset + 2]
        if left < 0 or right < left or right >= n:
            return None
        queries.append((left, right))
    return array, queries


def _sqrt_tree_answers(array: list[int], queries: list[tuple[int, int]]) -> list[int]:
    n = len(array)
    padded_size = 1
    while padded_size < n:
        padded_size *= 2
    log_n = padded_size.bit_length() - 1
    values = array + [INF] * (padded_size - n)

    floor_log = [0] * (padded_size + 1)
    for value in range(2, padded_size + 1):
        floor_log[value] = floor_log[value // 2] + 1

    layer_shapes: list[tuple[int, int]] = []
    segment_bits = log_n
    while segment_bits > 1:
        block_bits = (segment_bits + 1) // 2
        layer_shapes.append((segment_bits, block_bits))
        segment_bits = block_bits

    prefix = [[INF] * padded_size for _ in range(MAX_LEVELS)]
    suffix = [[INF] * padded_size for _ in range(MAX_LEVELS)]
    # Each level needs at most padded_size entries: parent_count * block_count^2 <= N.
    between = [[INF] * padded_size for _ in range(MAX_LEVELS)]
    layer_for_diff = [-1] * (log_n + 1)

    for level, (segment_bits, block_bits) in enumerate(layer_shapes):
        segment_size = 1 << segment_bits
        block_size = 1 << block_bits
        block_count = segment_size // block_size
        pair_count = block_count * block_count
        for diff_bit in range(block_bits, segment_bits):
            layer_for_diff[diff_bit] = level
        for base in range(0, padded_size, segment_size):
            segment_index = base // segment_size
            for block in range(block_count):
                start = base + block * block_size
                end = start + block_size
                prefix[level][start] = values[start]
                for index in range(start + 1, end):
                    prefix[level][index] = min(prefix[level][index - 1], values[index])
                suffix[level][end - 1] = values[end - 1]
                for index in range(end - 2, start - 1, -1):
                    suffix[level][index] = min(values[index], suffix[level][index + 1])
            for left_block in range(block_count):
                aggregate = INF
                for right_block in range(left_block, block_count):
                    block_start = base + right_block * block_size
                    aggregate = min(aggregate, suffix[level][block_start])
                    slot = segment_index * pair_count + left_block * block_count + right_block
                    between[level][slot] = aggregate

    answers = []
    for left, right in queries:
        if left == right:
            answers.append(array[left])
            continue
        difference = left ^ right
        diff_bit = floor_log[difference]
        if diff_bit == 0:
            answers.append(min(array[left], array[right]))
            continue
        level = layer_for_diff[diff_bit]
        segment_bits, block_bits = layer_shapes[level]
        segment_size = 1 << segment_bits
        block_size = 1 << block_bits
        base = (left // segment_size) * segment_size
        segment_index = base // segment_size
        left_block = (left - base) // block_size
        right_block = (right - base) // block_size
        answer = min(suffix[level][left], prefix[level][right])
        if left_block + 1 < right_block:
            block_count = segment_size // block_size
            pair_count = block_count * block_count
            slot = (segment_index * pair_count
                    + (left_block + 1) * block_count + right_block - 1)
            answer = min(answer, between[level][slot])
        answers.append(answer)
    return answers


def _encode_i64s(values: list[int]) -> bytes:
    return b"".join(int(value).to_bytes(8, "little", signed=True) for value in values)


def expected_output(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return b""
    array, queries = parsed
    return _encode_i64s(_sqrt_tree_answers(array, queries))


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return INVALID_RESULT
    return 8 * len(parsed[1])
