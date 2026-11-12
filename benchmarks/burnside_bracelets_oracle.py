"""Exhaustive orbit oracle for bounded dihedral colorings of a cycle."""

from functools import lru_cache
from itertools import product
import struct

MAX_N = 10
MAX_COLORS = 3
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 8


@lru_cache(maxsize=None)
def _count_orbits(n, colors):
    representatives = set()
    for coloring in product(range(colors), repeat=n):
        orbit = []
        for shift in range(n):
            rotated = [0] * n
            reflected = [0] * n
            for position, color in enumerate(coloring):
                rotated[(position + shift) % n] = color
                reflected[(shift - position) % n] = color
            orbit.append(tuple(rotated))
            orbit.append(tuple(reflected))
        representatives.add(min(orbit))
    return len(representatives)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(status, bytes)`` for ``[N, color_count]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1, b""
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return -1, b""
    n, colors = values
    if not 1 <= n <= MAX_N or not 0 <= colors <= MAX_COLORS:
        return -1, b""

    encoded = struct.pack("<q", _count_orbits(n, colors))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    return MAX_OUTPUT_BYTES, encoded
