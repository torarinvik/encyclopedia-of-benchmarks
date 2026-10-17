"""Independent oracle for the bounded TheAlgorithms/JavaScript shuf port."""

from __future__ import annotations

MAX_ITEMS = 32
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_ITEMS
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1  # permits one extra malformed value
MAX_OUTPUT_BYTES = MAX_ITEMS * 4
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Apply the source's two sampling passes and model output-buffer status."""
    if (type(output_is_null) is not bool
            or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))
            or input_is_null
            or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""

    count, sample_size = values[:2]
    if not 0 <= count <= MAX_ITEMS or not 1 <= sample_size <= MAX_ITEMS:
        return INVALID_RESULT, b""
    if len(values) != 2 + 2 * count:
        return INVALID_RESULT, b""

    items = values[2:2 + count]
    draws = values[2 + count:]
    if any(not I32_MIN <= item <= I32_MAX for item in items):
        return INVALID_RESULT, b""

    sample: list[int | None] = [None] * sample_size
    first_count = min(count, sample_size)
    for index in range(first_count):
        slot = draws[index]
        if not 0 <= slot < sample_size:
            return INVALID_RESULT, b""
        while sample[slot] is not None:
            slot += 1
            if slot == sample_size:
                slot = 0
        sample[slot] = items[index]

    if count < sample_size:
        sample = [value for value in sample if value is not None]
    else:
        for index in range(sample_size, count):
            bound = index + 1
            slot = draws[index]
            if not 0 <= slot < bound:
                return INVALID_RESULT, b""
            if slot < sample_size:
                sample[slot] = items[index]

    output = b"".join(
        (item & 0xFFFF_FFFF).to_bytes(4, "little")
        for item in sample
        if item is not None
    )
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output) // 4, output
