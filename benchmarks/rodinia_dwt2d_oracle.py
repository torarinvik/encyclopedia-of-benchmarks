"""Independent bounded integer 5/3 2D DWT model for Rodinia DWT2D."""

from collections.abc import Sequence
import struct

MAX_SIDE = 16
MAX_CELLS = MAX_SIDE * MAX_SIDE
MAX_INPUT_LENGTH = 3 + MAX_CELLS
MAX_OUTPUT_BYTES = 4 * MAX_CELLS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _split_lift(samples: list[int]) -> list[int]:
    """Return low coefficients then details using the source's integer steps."""
    half = len(samples) // 2
    evens = samples[0::2]
    odds = samples[1::2]
    details: list[int] = []
    for j, odd in enumerate(odds):
        right = evens[j + 1] if j + 1 < half else evens[j]
        # Python // floors; the C++ source uses signed division truncating to 0.
        pair_sum = evens[j] + right
        prediction = abs(pair_sum) // 2
        if pair_sum < 0:
            prediction = -prediction
        details.append(odd - prediction)
    first_update_sum = details[0] + details[0] + 2
    first_update = abs(first_update_sum) // 4
    if first_update_sum < 0:
        first_update = -first_update
    lows = [evens[0] + first_update]
    for j in range(1, half):
        update_sum = details[j - 1] + details[j] + 2
        update = abs(update_sum) // 4
        if update_sum < 0:
            update = -update
        lows.append(evens[j] + update)
    return lows + details


def _transform(width: int, height: int, levels: int, pixels: Sequence[int]) -> list[int]:
    plane = [[int(pixels[y * width + x]) - 128 for x in range(width)] for y in range(height)]
    active_width, active_height = width, height
    for _ in range(levels):
        vertically_packed = [[0] * width for _ in range(height)]
        for x in range(active_width):
            column = _split_lift([plane[y][x] for y in range(active_height)])
            for y, value in enumerate(column):
                vertically_packed[y][x] = value
        for y in range(active_height):
            row = _split_lift(vertically_packed[y][:active_width])
            vertically_packed[y][:active_width] = row
        for y in range(active_height):
            plane[y][:active_width] = vertically_packed[y][:active_width]
        active_width //= 2
        active_height //= 2
    packed: list[int] = []
    for stage in range(levels - 1, -1, -1):
        stage_width = width >> stage
        stage_height = height >> stage
        half_width = stage_width // 2
        half_height = stage_height // 2
        if stage == levels - 1:
            packed.extend(plane[y][x] for y in range(half_height) for x in range(half_width))
        packed.extend(plane[y][x] for y in range(half_height) for x in range(half_width, stage_width))
        packed.extend(plane[y][x] for y in range(half_height, stage_height) for x in range(half_width))
        packed.extend(plane[y][x] for y in range(half_height, stage_height)
                      for x in range(half_width, stage_width))
    return packed


def expected_output(values: Sequence[int]) -> bytes | None:
    if not isinstance(values, (tuple, list)) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    width, height, levels = values[:3]
    if not (2 <= width <= MAX_SIDE and 2 <= height <= MAX_SIDE and 1 <= levels <= 3):
        return None
    factor = 1 << levels
    if width < factor or height < factor or width % factor or height % factor:
        return None
    cells = width * height
    if len(values) != 3 + cells or any(value < 0 or value > 255 for value in values[3:]):
        return None
    coefficients = _transform(width, height, levels, values[3:])
    return b"".join(struct.pack("<i", value) for value in coefficients)


def expected_result(values: Sequence[int], output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False) -> int:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or
            type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT
    if input_is_null:
        if values or output_is_null:
            return INVALID_RESULT
        return INVALID_RESULT
    result = expected_output(values)
    if result is None:
        return INVALID_RESULT
    if output_is_null or output_capacity < len(result):
        return OUTPUT_ERROR
    return len(result)
