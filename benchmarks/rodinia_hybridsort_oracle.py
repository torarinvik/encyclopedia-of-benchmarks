"""Independent integer model for the bounded Rodinia HybridSort profile."""

from collections.abc import Sequence
import struct

MAX_ITEMS = 64
MAX_INPUT_LENGTH = MAX_ITEMS + 1
MAX_OUTPUT_BYTES = MAX_ITEMS * 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: Sequence[int]) -> bytes | None:
    """Return the little-endian sorted vector, or None for malformed input."""
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    count = values[0]
    if not 2 <= count <= MAX_ITEMS or len(values) != count + 1:
        return None
    items = values[1:]
    if any(value < 0 or value > 1_000_000 or value % 1000 != 0 for value in items):
        return None
    if min(items) == max(items):
        return None
    # This oracle uses Python's independent comparison sort rather than the
    # ports' histogram/scatter/per-bucket merge-sort pipeline.
    return b"".join(struct.pack("<q", value) for value in sorted(items))


def expected_result(values: Sequence[int], output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False) -> int:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT
    if input_is_null:
        return INVALID_RESULT
    output = expected_output(values)
    if output is None:
        return INVALID_RESULT
    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR
    return len(output)
