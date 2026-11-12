"""Independent target-wise direct oracle for the bounded spatial profile."""

from collections.abc import Sequence

from water_spatial_oracle import (
    MAX_CUTOFF, MAX_PARSEABLE_INPUT_LENGTH, MAX_MOLECULES, SCALE,
)


def _signed_quotient(numerator: int, denominator: int) -> int:
    magnitude = abs(numerator) // denominator
    return -magnitude if numerator < 0 else magnitude


def _valid(values: Sequence[int] | None, input_length: int | None):
    if (values is None or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count, grid_side, cutoff = values[:3]
    if (not 0 <= count <= MAX_MOLECULES or not 1 <= grid_side <= 8
            or not 1 <= cutoff <= MAX_CUTOFF or len(values) != 3 + 4 * count):
        return None
    extent = grid_side * cutoff
    particles = []
    for offset in range(3, len(values), 4):
        x, y, z, charge = values[offset:offset + 4]
        if (not 0 <= x < extent or not 0 <= y < extent or not 0 <= z < extent
                or not -4 <= charge <= 4):
            return None
        particles.append((x, y, z, charge))
    return count, cutoff, particles


def evaluate(values: Sequence[int] | None,
             input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _valid(values, input_length)
    if parsed is None:
        return -1, b""
    count, cutoff, particles = parsed
    cutoff_squared = cutoff * cutoff
    forces = [[0, 0, 0] for _ in range(count)]
    energy = 0
    pairs = 0
    # For each target, sum its force from every other molecule. Energy is
    # counted only from the lower-index endpoint to avoid double counting.
    for target, (x0, y0, z0, q0) in enumerate(particles):
        for other, (x1, y1, z1, q1) in enumerate(particles):
            if target == other:
                continue
            delta = (x1 - x0, y1 - y0, z1 - z0)
            radius_squared = sum(value * value for value in delta)
            if radius_squared >= cutoff_squared:
                continue
            product = q0 * q1
            denominator = (1 + radius_squared) ** 2
            for axis in range(3):
                forces[target][axis] += _signed_quotient(
                    -2 * product * delta[axis] * SCALE, denominator)
            if target < other:
                energy += _signed_quotient(
                    product * (cutoff_squared - radius_squared) * SCALE,
                    (1 + radius_squared) * (1 + cutoff_squared))
                pairs += 1
    output = [component for force in forces for component in force]
    output.extend((energy, pairs))
    encoded = b"".join(value.to_bytes(8, "little", signed=True) for value in output)
    return len(encoded), encoded


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
                (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return -1, b""
    if input_is_null:
        return -1, b""
    result, encoded = evaluate(values, input_length)
    if result < 0:
        return result, encoded
    if output_is_null or capacity is not None and capacity < result:
        return -2, b""
    return result, encoded
