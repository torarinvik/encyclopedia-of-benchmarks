"""Independent oracle for the bounded IJG 2x2 fancy chroma upsampler profile."""
from __future__ import annotations

from collections.abc import Sequence

MAX_WIDTH = 16
MAX_HEIGHT = 8
MAX_INPUT_LENGTH = 2 + MAX_WIDTH * MAX_HEIGHT
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 4 * MAX_WIDTH * MAX_HEIGHT


def _valid(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (input_is_null or values is None or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    if not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    width, height = values[0], values[1]
    if not 3 <= width <= MAX_WIDTH or not 1 <= height <= MAX_HEIGHT:
        return None
    if len(values) != 2 + width * height or any(not 0 <= v <= 255 for v in values[2:]):
        return None
    return width, height


def calculate(values: Sequence[int]) -> bytes:
    width, height = values[0], values[1]
    pixels = values[2:]
    out = bytearray(4 * width * height)

    def sample(y: int, x: int) -> int:
        # The source's context rows/edge columns are supplied by edge replication.
        return pixels[min(height - 1, max(0, y)) * width + min(width - 1, max(0, x))]

    p = 0
    for y in range(height):
        for vertical_neighbor in (y - 1, y + 1):
            sums = [3 * sample(y, x) + sample(vertical_neighbor, x) for x in range(width)]
            out[p] = (4 * sums[0] + 8) >> 4
            p += 1
            out[p] = (3 * sums[0] + sums[1] + 7) >> 4
            p += 1
            for x in range(1, width - 1):
                out[p] = (3 * sums[x] + sums[x - 1] + 8) >> 4
                p += 1
                out[p] = (3 * sums[x] + sums[x + 1] + 7) >> 4
                p += 1
            out[p] = (3 * sums[-1] + sums[-2] + 8) >> 4
            p += 1
            out[p] = (4 * sums[-1] + 7) >> 4
            p += 1
    return bytes(out)


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    shape = _valid(values, input_is_null, input_length)
    if shape is None:
        return -1, b""
    if (type(output_is_null) is not bool or type(output_capacity) is not int
            or output_capacity < 0):
        return -1, b""
    result = calculate(values)
    if output_is_null or output_capacity < len(result):
        return -2, b""
    return len(result), result


oracle = expected_output
