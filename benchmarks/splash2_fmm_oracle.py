"""Direct all-pairs reference for the bounded SPLASH-2 FMM profile."""

from collections.abc import Sequence
from math import hypot, isfinite, log

MAX_PARTICLES = 48
MAX_INPUT_LENGTH = 1 + 3 * MAX_PARTICLES


def _parse(values: Sequence[float] | None, input_length: int | None):
    if (values is None or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))):
        return None
    if any(type(value) not in (int, float) or not isfinite(value) for value in values):
        return None
    count_value = values[0]
    if (count_value != int(count_value) or not 2 <= count_value <= MAX_PARTICLES
            or len(values) != 1 + 3 * int(count_value)):
        return None
    count = int(count_value)
    seen = set()
    for index in range(count):
        x, y, charge = values[1 + 3 * index:4 + 3 * index]
        if (x != int(x) or y != int(y) or not 0 <= x < 8 or not 0 <= y < 8
                or charge != int(charge) or not -3 <= charge <= 3):
            return None
        point = (int(x), int(y))
        if point in seen:
            return None
        seen.add(point)
    return count


def evaluate(values: Sequence[float] | None,
             input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    """Evaluate the two-dimensional logarithmic potential by direct summation."""
    count = _parse(values, input_length)
    if count is None:
        return -1, ()
    particles = [tuple(float(value) for value in values[1 + 3 * i:4 + 3 * i])
                 for i in range(count)]
    potentials = []
    for tx, ty, _ in particles:
        value = 0.0
        for sx, sy, charge in particles:
            dx, dy = sx - tx, sy - ty
            if dx != 0.0 or dy != 0.0:
                value += charge * log(hypot(dx, dy))
        potentials.append(value)
    return count, tuple(potentials)


def expected_output(values: Sequence[float] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and
                (type(capacity) is not int or capacity < 0)
            or input_length is not None and
                (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, ()
    if input_is_null:
        return -1, ()
    result, output = evaluate(values, input_length)
    if result < 0:
        return result, output
    if output_is_null or capacity is not None and capacity < result:
        return -2, ()
    return result, output
