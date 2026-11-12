"""Direct all-pairs oracle for the bounded SPLASH-2-inspired spatial profile."""

from collections.abc import Sequence
import struct

MAX_MOLECULES = 64
MAX_GRID_SIDE = 8
MAX_CUTOFF = 4
MAX_VALID_INPUT_LENGTH = 3 + 4 * MAX_MOLECULES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * (3 * MAX_MOLECULES + 2)
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES
MAX_INTERNAL_STORAGE_BYTES = 8 * (512 + MAX_MOLECULES + 3 * MAX_MOLECULES + 2)
SCALE = 1_000_000


def _trunc_div(numerator: int, denominator: int) -> int:
    """Signed integer division truncated toward zero."""
    if numerator < 0:
        return -((-numerator) // denominator)
    return numerator // denominator


def _parse(values: Sequence[int] | None, input_length: int | None):
    if (values is None or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count, grid_side, cutoff = values[:3]
    if (not 0 <= count <= MAX_MOLECULES
            or not 1 <= grid_side <= MAX_GRID_SIDE
            or not 1 <= cutoff <= MAX_CUTOFF
            or len(values) != 3 + 4 * count):
        return None
    extent = grid_side * cutoff
    for index in range(count):
        x, y, z, charge = values[3 + 4 * index:7 + 4 * index]
        if (not 0 <= x < extent or not 0 <= y < extent or not 0 <= z < extent
                or not -4 <= charge <= 4):
            return None
    return count, grid_side, cutoff


def evaluate(values: Sequence[int] | None,
             input_length: int | None = None) -> tuple[int, bytes]:
    """Return forces, shifted pair energy, and accepted pair count by all pairs."""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    count, _, cutoff = parsed
    cutoff_squared = cutoff * cutoff
    forces = [[0, 0, 0] for _ in range(count)]
    total_energy = 0
    accepted_pairs = 0
    for left in range(count):
        x1, y1, z1, q1 = values[3 + 4 * left:7 + 4 * left]
        for right in range(left + 1, count):
            x2, y2, z2, q2 = values[3 + 4 * right:7 + 4 * right]
            dx, dy, dz = x2 - x1, y2 - y1, z2 - z1
            distance_squared = dx * dx + dy * dy + dz * dz
            if distance_squared >= cutoff_squared:
                continue
            charge_product = q1 * q2
            shifted_numerator = charge_product * (cutoff_squared - distance_squared) * SCALE
            shifted_denominator = (1 + distance_squared) * (1 + cutoff_squared)
            total_energy += _trunc_div(shifted_numerator, shifted_denominator)
            force_denominator = (1 + distance_squared) ** 2
            pair_force = [
                _trunc_div(-2 * charge_product * delta * SCALE, force_denominator)
                for delta in (dx, dy, dz)
            ]
            for axis in range(3):
                forces[left][axis] += pair_force[axis]
                forces[right][axis] -= pair_force[axis]
            accepted_pairs += 1
    flattened = [component for force in forces for component in force]
    flattened.extend((total_energy, accepted_pairs))
    encoded = b"".join(struct.pack("<q", value) for value in flattened)
    return len(encoded), encoded


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
                (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return -1, b""
    if input_is_null:
        return -1, b""
    result, encoded = evaluate(values, input_length)
    if result < 0:
        return result, encoded
    if output_is_null or capacity is not None and capacity < result:
        return -2, b""
    return result, encoded
