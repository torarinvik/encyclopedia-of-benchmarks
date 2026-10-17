"""Oracle for the bounded Java long-valued running median."""

from __future__ import annotations

from collections.abc import Sequence

MIN_SAMPLE = -(1 << 62)
MAX_SAMPLE = (1 << 62) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_SAMPLE_COUNT = 1
MAX_SAMPLE_COUNT = 64
MAX_VALID_INPUT_WORDS = 1 + MAX_SAMPLE_COUNT
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_WORDS
MAX_OUTPUT_BYTES = 8 * MAX_SAMPLE_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _truncating_average(lower: int, upper: int) -> int:
    """Match Java signed long division, which truncates toward zero."""
    total = lower + upper
    return total // 2 if total >= 0 else -((-total) // 2)


def _median_of_prefix(samples: Sequence[int]) -> int:
    """Return the center long or average the two center longs as Java does."""
    ordered = sorted(samples)
    middle = len(ordered) // 2
    if len(ordered) % 2:
        return ordered[middle]
    return _truncating_average(ordered[middle - 1], ordered[middle])


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return little-endian i64 prefix medians or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    sample_count = values[0]
    if not MIN_SAMPLE_COUNT <= sample_count <= MAX_SAMPLE_COUNT:
        return INVALID_RESULT, b""
    if len(values) != 1 + sample_count:
        return INVALID_RESULT, b""
    samples = values[1:]
    if any(not MIN_SAMPLE <= sample <= MAX_SAMPLE for sample in samples):
        return INVALID_RESULT, b""

    prefix: list[int] = []
    encoded = bytearray()
    for sample in samples:
        prefix.append(sample)
        median = _median_of_prefix(prefix)
        encoded.extend(median.to_bytes(8, byteorder="little", signed=True))
    output = bytes(encoded)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
