"""Exact direct-pair oracle for the bounded SPLASH-2-inspired water profile."""

from __future__ import annotations

import struct

MAX_MOLECULES = 64
MAX_VALID_INPUT_VALUES = 3 + 4 * MAX_MOLECULES
MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1
MAX_OUTPUT_BYTES = 8 * (3 * MAX_MOLECULES + 2)
SCALE = 1_000_000


def _trunc_div(numerator: int, denominator: int) -> int:
    magnitude = abs(numerator) // denominator
    return -magnitude if numerator < 0 else magnitude


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 3 <= input_length <= MAX_PARSEABLE_INPUT_VALUES):
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return None
    n, grid, radius = values[:3]
    if not 0 <= n <= MAX_MOLECULES or not 1 <= grid <= 8 or not 1 <= radius <= 4:
        return None
    if len(values) != 3 + 4 * n:
        return None
    side = grid * radius
    molecules = []
    for at in range(3, len(values), 4):
        x, y, z, charge = values[at:at + 4]
        if (not 0 <= x < side or not 0 <= y < side or not 0 <= z < side
                or not -4 <= charge <= 4):
            return None
        molecules.append((x, y, z, charge))
    return radius, molecules


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    radius, molecules = parsed
    force = [[0, 0, 0] for _ in molecules]
    energy = 0
    accepted_pairs = 0
    radius2 = radius * radius
    for i in range(len(molecules)):
        xi, yi, zi, qi = molecules[i]
        for j in range(i + 1, len(molecules)):
            xj, yj, zj, qj = molecules[j]
            dx, dy, dz = xj - xi, yj - yi, zj - zi
            r2 = dx * dx + dy * dy + dz * dz
            if r2 >= radius2:
                continue
            product = qi * qj
            energy += _trunc_div(product * (radius2 - r2) * SCALE,
                                 (1 + r2) * (1 + radius2))
            denominator = (1 + r2) ** 2
            pair_force = tuple(_trunc_div(-2 * product * delta * SCALE, denominator)
                               for delta in (dx, dy, dz))
            for axis, component in enumerate(pair_force):
                force[i][axis] += component
                force[j][axis] -= component
            accepted_pairs += 1
    words = [component for row in force for component in row]
    words.extend((energy, accepted_pairs))
    payload = struct.pack("<" + "q" * len(words), *words)
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int or capacity < 0):
        return -2, b""
    if output_is_null or capacity < len(payload):
        return -2, b""
    return len(payload), payload
