# Copyright (c) 1988-1997 Sam Leffler
# Copyright (c) 1991-1997 Silicon Graphics, Inc.
#
# Permission to use, copy, modify, distribute, and sell this software and
# its documentation for any purpose is hereby granted without fee, provided
# that (i) the above copyright notices and this permission notice appear in
# all copies of the software and related documentation, and (ii) the names of
# Sam Leffler and Silicon Graphics may not be used in any advertising or
# publicity relating to the software without the specific, prior written
# permission of Sam Leffler and Silicon Graphics.
#
# THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND,
# EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
# WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
#
# IN NO EVENT SHALL SAM LEFFLER OR SILICON GRAPHICS BE LIABLE FOR
# ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
# OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
# WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF
# LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
# OF THIS SOFTWARE.

"""Independent bounded oracle for the cBench TIFF Floyd--Steinberg core."""

from __future__ import annotations

from collections.abc import Sequence

MAX_WIDTH = 32
MAX_HEIGHT = 16
MAX_INPUT_LENGTH = 3 + MAX_WIDTH * MAX_HEIGHT
MAX_OUTPUT_BYTES = ((MAX_WIDTH + 7) // 8) * (MAX_HEIGHT - 1)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _trunc_div(value: int, divisor: int) -> int:
    """C-style signed integer division, rounded toward zero."""
    return value // divisor if value >= 0 else -((-value) // divisor)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 5
            or actual_length > MAX_INPUT_LENGTH or len(values) != actual_length):
        return INVALID_RESULT, b""

    width, height, threshold = values[:3]
    if not 1 <= width <= MAX_WIDTH or not 2 <= height <= MAX_HEIGHT:
        return INVALID_RESULT, b""
    if not 0 <= threshold <= 255 or actual_length != 3 + width * height:
        return INVALID_RESULT, b""
    pixels = values[3:]
    if any(pixel < 0 or pixel > 255 for pixel in pixels):
        return INVALID_RESULT, b""

    row_bytes = (width + 7) // 8
    output_size = row_bytes * (height - 1)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < output_size)):
        return OUTPUT_ERROR, b""

    packed = bytearray(output_size)
    this_line = list(pixels[:width])
    next_line = list(this_line)
    for row in range(1, height):
        this_line, next_line = next_line, this_line
        start = row * width
        next_line[:] = pixels[start:start + width]
        last_line = row == height - 1
        for column in range(width):
            value = this_line[column]
            if value < 0:
                value = 0
            elif value > 255:
                value = 255

            if value > threshold:
                out_row = row - 1
                packed[out_row * row_bytes + column // 8] |= 0x80 >> (column % 8)
                value -= 255

            if column + 1 < width:
                this_line[column + 1] += _trunc_div(value * 7, 16)
            if not last_line:
                if column > 0:
                    next_line[column - 1] += _trunc_div(value * 3, 16)
                next_line[column] += _trunc_div(value * 5, 16)
                if column + 1 < width:
                    next_line[column + 1] += _trunc_div(value, 16)

    return output_size, bytes(packed)
