"""Independent reference using an octant index and direct HSV sector table."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _phase_index(u: int, v: int) -> int:
    if u == 0 and v == 0:
        return 0
    abs_u, abs_v = abs(u), abs(v)
    larger = max(abs_u, abs_v)
    progress = (abs_u if abs_u < abs_v else abs_v) * 192 // larger

    if v >= 0 and u >= 0:
        octant = 0 if abs_u >= abs_v else 1
    elif v >= 0:
        octant = 2 if abs_u < abs_v else 3
    elif u < 0:
        octant = 4 if abs_u >= abs_v else 5
    else:
        octant = 6 if abs_u < abs_v else 7

    phase = octant * 192 + (progress if octant % 2 == 0 else 192 - progress)
    return phase - 1536 if phase == 1536 else phase


def _pixel(u: int, v: int, magnitude_16: int) -> tuple[int, int, int]:
    phase = _phase_index(u, v)
    section = phase >> 8
    part = phase & 255
    brightness = 128 + ((magnitude_16 & 15) << 3)
    up = (brightness * part) // 255
    down = (brightness * (255 - part)) // 255
    sector_channels = (
        (brightness, up, 0),
        (down, brightness, 0),
        (0, brightness, up),
        (0, down, brightness),
        (up, 0, brightness),
        (brightness, 0, down),
    )
    return sector_channels[section]


def _valid(values: Sequence[int] | None) -> tuple[int, int, int, int, int, int] | None:
    if (
        not isinstance(values, (list, tuple))
        or len(values) != 6
        or any(type(item) is not int or not I64_MIN <= item <= I64_MAX for item in values)
    ):
        return None
    width, height, x0, y0, dx, dy = values
    if width not in range(1, 17) or height not in range(1, 17):
        return None
    if x0 not in range(-32, 33) or y0 not in range(-32, 33):
        return None
    if dx not in range(-8, 9) or dy not in range(-8, 9):
        return None
    if x0 + (width - 1) * dx not in range(-32, 33):
        return None
    if y0 + (height - 1) * dy not in range(-32, 33):
        return None
    return width, height, x0, y0, dx, dy


def render(values: Sequence[int] | None) -> bytes | None:
    decoded = _valid(values)
    if decoded is None:
        return None
    width, height, x0, y0, dx, dy = decoded
    output = bytearray()
    yq = y0
    for _ in range(height):
        xq = x0
        for _ in range(width):
            real = xq * xq - yq * yq
            imag = (xq * yq) << 1
            mag16 = xq * xq + yq * yq
            output.extend(_pixel(real, imag, mag16))
            xq += dx
        yq += dy
    return bytes(output)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null:
        return -1, b""
    if input_length is not None and (
        type(input_length) is not int
        or not isinstance(values, (list, tuple))
        or input_length != len(values)
    ):
        return -1, b""
    output = render(values)
    if output is None:
        return -1, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return -2, b""
    return len(output), output
