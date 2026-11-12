"""Independent target-wise oracle for the bounded Fluidanimate SPH update."""

from __future__ import annotations

import math
import struct
from typing import Sequence

from parsec_fluidanimate_sph_oracle import (
    COORDINATE_LIMIT_MILLI,
    DOUBLE_REST_DENSITY,
    EXTERNAL_ACCELERATION,
    H_RADIUS_MULTIPLIER,
    INVALID_RESULT,
    MAX_INPUT_LENGTH,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PARTICLES,
    MAX_RPM_MILLI,
    MIN_RPM_MILLI,
    OUTPUT_ERROR,
    PI,
    PRESSURE_STIFFNESS,
    REST_DENSITY,
    VELOCITY_LIMIT_MILLI,
    VISCOSITY,
)


def _valid(values: Sequence[int], input_length: int | None) -> bool:
    if input_length is None or type(input_length) is not int:
        return False
    if not 2 <= input_length <= MAX_INPUT_LENGTH or input_length != len(values):
        return False
    if input_length > MAX_PARSEABLE_INPUT_LENGTH:
        return False
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return False
    count, rpm_milli = values[0], values[1]
    if not 1 <= count <= MAX_PARTICLES or not MIN_RPM_MILLI <= rpm_milli <= MAX_RPM_MILLI:
        return False
    if input_length != 2 + 6 * count:
        return False
    for particle in range(count):
        base = 2 + 6 * particle
        if any(abs(values[base + axis]) > COORDINATE_LIMIT_MILLI for axis in range(3)):
            return False
        if any(abs(values[base + axis]) > VELOCITY_LIMIT_MILLI for axis in range(3, 6)):
            return False
    return True


def _targetwise(values: Sequence[int]) -> list[float]:
    count = values[0]
    rpm = values[1] / 1000.0
    h = H_RADIUS_MULTIPLIER / rpm
    h2 = h * h
    mass = REST_DENSITY / (rpm * rpm * rpm)
    density_coeff = mass * (315.0 / (64.0 * PI * (h ** 9)))
    pressure_coeff = (3.0 * (15.0 / (PI * (h ** 6)))
                      * 0.5 * PRESSURE_STIFFNESS * mass)
    viscosity_coeff = VISCOSITY * (45.0 / (PI * (h ** 6))) * mass
    positions = []
    velocities = []
    for particle in range(count):
        base = 2 + 6 * particle
        positions.append(tuple(values[base + axis] * 0.001 for axis in range(3)))
        velocities.append(tuple(values[base + 3 + axis] * 0.001 for axis in range(3)))

    densities = []
    for i in range(count):
        density_sum = h2 * h2 * h2
        for j in range(count):
            if i == j:
                continue
            r2 = sum((positions[i][axis] - positions[j][axis]) ** 2 for axis in range(3))
            if r2 < h2:
                density_sum += (h2 - r2) ** 3
        densities.append(density_sum * density_coeff)

    output: list[float] = []
    for i in range(count):
        acceleration = list(EXTERNAL_ACCELERATION)
        for j in range(count):
            if i == j:
                continue
            displacement = tuple(positions[i][axis] - positions[j][axis] for axis in range(3))
            r2 = sum(component * component for component in displacement)
            if r2 >= h2:
                continue
            distance = math.sqrt(max(r2, 1e-12))
            hmr = h - distance
            density_product = densities[i] * densities[j]
            pressure_factor = (pressure_coeff * (hmr * hmr / distance)
                               * (densities[i] + densities[j] - DOUBLE_REST_DENSITY)
                               / density_product)
            viscosity_factor = viscosity_coeff * hmr / density_product
            for axis in range(3):
                acceleration[axis] += (displacement[axis] * pressure_factor
                                       + (velocities[j][axis] - velocities[i][axis])
                                       * viscosity_factor)
        output.extend((densities[i], PRESSURE_STIFFNESS * (densities[i] - REST_DENSITY),
                       *acceleration))
    return output


def expected_output(values: Sequence[int], output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_is_null or not _valid(values, input_length):
        return INVALID_RESULT, b""
    output_bytes = 40 * values[0]
    if output_is_null or output_capacity is None or output_capacity < output_bytes:
        return OUTPUT_ERROR, b""
    vector = _targetwise(values)
    return output_bytes, struct.pack("<" + "d" * len(vector), *vector)

