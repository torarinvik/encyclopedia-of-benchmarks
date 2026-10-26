"""Independent brute-force oracle for the bounded ParGeo BCP profile."""

from collections.abc import Sequence
import struct

MAX_POINTS_PER_COLOR = 8
MAX_COORDINATE = 1_000_000
MAX_INPUT_LENGTH = 2 + 4 * MAX_POINTS_PER_COLOR
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
OUTPUT_BYTES = 8
MAX_OUTPUT_BYTES = OUTPUT_BYTES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _payload(values: Sequence[int], input_length: int | None = None) -> bytes | None:
    if not isinstance(values, (list, tuple)) or not 10 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int for value in values):
        return None
    n_a, n_b = values[:2]
    if not 2 <= n_a <= MAX_POINTS_PER_COLOR or not 2 <= n_b <= MAX_POINTS_PER_COLOR:
        return None
    if len(values) != 2 + 2 * (n_a + n_b):
        return None
    coordinates = values[2:]
    if any(value < -MAX_COORDINATE or value > MAX_COORDINATE for value in coordinates):
        return None
    split = 2 * n_a
    red = list(zip(coordinates[:split:2], coordinates[1:split:2]))
    blue = list(zip(coordinates[split::2], coordinates[split + 1::2]))

    # Deliberately independent from the package's KD-tree construction and
    # branch-and-bound traversal.
    best = min((ax - bx) ** 2 + (ay - by) ** 2
               for ax, ay in red for bx, by in blue)
    return struct.pack("<q", best)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or values is not None and not isinstance(values, (list, tuple))
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    payload = _payload(values, input_length)
    if payload is None:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity is not None and output_capacity < OUTPUT_BYTES:
        return OUTPUT_ERROR, b""
    return OUTPUT_BYTES, payload
