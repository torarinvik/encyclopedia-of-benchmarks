"""Independent oracle for the synthetic-ID XOR linked-list traversal."""

from collections.abc import Sequence


MAX_COUNT = 64
MAX_VALID_INPUT_LENGTH = MAX_COUNT + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_COUNT + 2
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 + MAX_COUNT * 8
INVALID_RESULT = -1
CAPACITY_ERROR = -2
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _i64_le(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=True)


def expected_output(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""

    count = values[0]
    items = values[1:]
    if not 0 <= count <= MAX_COUNT or len(values) != count + 1:
        return INVALID_RESULT, b""
    if any(not I32_MIN <= value <= I32_MAX for value in items):
        return INVALID_RESULT, b""

    # Synthetic IDs model object addresses while keeping the traversal deterministic.
    node_values: dict[int, int] = {}
    both: dict[int, int] = {}
    tail = 0
    for offset, value in enumerate(items, start=1):
        node_values[offset] = value
        both[offset] = tail
        if tail:
            both[tail] ^= offset
        tail = offset

    ordered: list[int] = []
    previous = 0
    current = 1 if count else 0
    while current:
        ordered.append(node_values[current])
        next_id = previous ^ both[current]
        previous, current = current, next_id

    output = _i64_le(count) + b"".join(_i64_le(value) for value in ordered)
    if capacity is not None and (type(capacity) is not int or capacity < len(output)):
        return CAPACITY_ERROR, b""
    return len(output), output
