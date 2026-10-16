"""Portable oracle for the normalized TheAlgorithms blob-detection pipeline."""

from __future__ import annotations

from collections import deque
from fractions import Fraction

MAX_SIDE = 128
MAX_CELLS = MAX_SIDE * MAX_SIDE
MAX_INPUT_LENGTH = 3 + 3 * MAX_CELLS
DISK_RADIUS = 3
DISK_OFFSETS = tuple(
    (dy, dx)
    for dy in range(-DISK_RADIUS, DISK_RADIUS + 1)
    for dx in range(-DISK_RADIUS, DISK_RADIUS + 1)
    if dx * dx + dy * dy <= DISK_RADIUS * DISK_RADIUS
)


def _is_target_color(red: int, green: int, blue: int, profile: int) -> bool:
    maximum = max(red, green, blue)
    minimum = min(red, green, blue)
    delta = maximum - minimum
    if maximum == 0 or delta == 0:
        return False
    if maximum == red:
        hue_numerator = (green - blue) % (6 * delta)
    elif maximum == green:
        hue_numerator = 2 * delta + blue - red
    else:
        hue_numerator = 4 * delta + red - green
    hue = Fraction(hue_numerator, 6 * delta)
    saturation = Fraction(delta, maximum)
    if profile == 0:
        hue_min, hue_max, saturation_min = Fraction(379, 1000), Fraction(496, 1000), Fraction(436, 1000)
    else:
        hue_min, hue_max, saturation_min = Fraction(398, 1000), Fraction(498, 1000), Fraction(355, 1000)
    return hue_min <= hue <= hue_max and saturation >= saturation_min


def blob_detection_count(values: list[int] | tuple[int, ...]) -> int:
    if (len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1
    height, width, profile = values[:3]
    if (not 1 <= height <= MAX_SIDE or not 1 <= width <= MAX_SIDE
            or profile not in (0, 1) or len(values) != 3 + 3 * height * width):
        return -1
    pixels = values[3:]
    if any(not 0 <= channel <= 255 for channel in pixels):
        return -1

    cells = height * width
    mask = [False] * cells
    for index in range(cells):
        red, green, blue = pixels[3 * index:3 * index + 3]
        mask[index] = _is_target_color(red, green, blue, profile)

    eroded = [False] * cells
    for row in range(height):
        for column in range(width):
            keep = True
            for dy, dx in DISK_OFFSETS:
                y, x = row + dy, column + dx
                # MATLAB binary erosion pads outside the image with foreground.
                if 0 <= y < height and 0 <= x < width and not mask[y * width + x]:
                    keep = False
                    break
            eroded[row * width + column] = keep

    opened = [False] * cells
    for row in range(height):
        for column in range(width):
            opened_here = False
            for dy, dx in DISK_OFFSETS:
                y, x = row + dy, column + dx
                # MATLAB binary dilation pads outside the image with background.
                if 0 <= y < height and 0 <= x < width and eroded[y * width + x]:
                    opened_here = True
                    break
            opened[row * width + column] = opened_here

    visited = [False] * cells
    object_count = 0
    for start in range(cells):
        if not opened[start] or visited[start]:
            continue
        visited[start] = True
        pending = deque([start])
        area = 0
        while pending:
            index = pending.popleft()
            area += 1
            row, column = divmod(index, width)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if dy == 0 and dx == 0:
                        continue
                    y, x = row + dy, column + dx
                    if 0 <= y < height and 0 <= x < width:
                        neighbor = y * width + x
                        if opened[neighbor] and not visited[neighbor]:
                            visited[neighbor] = True
                            pending.append(neighbor)
        if 200 <= area <= 5000:
            object_count += 1
            if object_count == 50:
                return object_count
    return object_count
