"""Bounded direct oracle for one PARSEC Fluidanimate SPH kernel update."""

from __future__ import annotations

import math
import struct
from typing import Sequence

MAX_PARTICLES = 32
MIN_RPM_MILLI = 500
MAX_RPM_MILLI = 5000
COORDINATE_LIMIT_MILLI = 10_000
VELOCITY_LIMIT_MILLI = 5_000
MAX_INPUT_LENGTH = 2 + 6 * MAX_PARTICLES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 40 * MAX_PARTICLES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
PI = 3.141592653589793
H_RADIUS_MULTIPLIER = 1.695
REST_DENSITY = 1000.0
DOUBLE_REST_DENSITY = 2000.0
PRESSURE_STIFFNESS = 3.0
VISCOSITY = 0.4
EXTERNAL_ACCELERATION = (0.0, -9.8, 0.0)


def _valid(values: Sequence[int], input_length: int | None) -> bool:
    if input_length is None or type(input_length) is not int:
        return False
    if not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH or input_length != len(values):
        return False
    if input_length < 2 or input_length > MAX_INPUT_LENGTH:
        return False
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return False
    count, rpm_milli = values[0], values[1]
    if not 1 <= count <= MAX_PARTICLES or not MIN_RPM_MILLI <= rpm_milli <= MAX_RPM_MILLI:
        return False
    if input_length != 2 + 6 * count:
        return False
    for index in range(count):
        base = 2 + 6 * index
        if any(abs(values[base + axis]) > COORDINATE_LIMIT_MILLI for axis in range(3)):
            return False
        if any(abs(values[base + axis]) > VELOCITY_LIMIT_MILLI for axis in range(3, 6)):
            return False
    return True


def _decode(values: Sequence[int]) -> tuple[list[tuple[float, float, float]],
                                             list[tuple[float, float, float]],
                                             list[float], float, float, float, float]:
    count, rpm_milli = values[0], values[1]
    rpm = rpm_milli / 1000.0
    h = H_RADIUS_MULTIPLIER / rpm
    h_squared = h * h
    particle_mass = REST_DENSITY / (rpm * rpm * rpm)
    density_coefficient = particle_mass * (315.0 / (64.0 * PI * (h ** 9)))
    pressure_coefficient = (3.0 * (15.0 / (PI * (h ** 6)))
                            * 0.5 * PRESSURE_STIFFNESS * particle_mass)
    viscosity_coefficient = VISCOSITY * (45.0 / (PI * (h ** 6))) * particle_mass
    positions = []
    velocities = []
    for index in range(count):
        base = 2 + 6 * index
        positions.append(tuple(values[base + axis] / 1000.0 for axis in range(3)))
        velocities.append(tuple(values[base + 3 + axis] / 1000.0 for axis in range(3)))
    return positions, velocities, [density_coefficient] * count, h, h_squared, pressure_coefficient, viscosity_coefficient


def _compute_pairwise(values: Sequence[int]) -> list[float]:
    positions, velocities, density_coefficients, h, h_squared, pressure_coeff, viscosity_coeff = _decode(values)
    count = len(positions)
    densities = [density_coefficients[i] * h_squared * h_squared * h_squared for i in range(count)]
    radii_squared: list[list[float]] = [[0.0] * count for _ in range(count)]
    for i in range(count):
        for j in range(i + 1, count):
            disp = tuple(positions[i][axis] - positions[j][axis] for axis in range(3))
            r2 = sum(component * component for component in disp)
            radii_squared[i][j] = r2
            if r2 < h_squared:
                tc = (h_squared - r2) ** 3
                densities[i] += density_coefficients[i] * tc
                densities[j] += density_coefficients[j] * tc
    accelerations = [[component for component in EXTERNAL_ACCELERATION] for _ in range(count)]
    for i in range(count):
        for j in range(i + 1, count):
            r2 = radii_squared[i][j]
            if r2 >= h_squared:
                continue
            disp = tuple(positions[i][axis] - positions[j][axis] for axis in range(3))
            distance = math.sqrt(max(r2, 1e-12))
            h_minus_r = h - distance
            density_product = densities[i] * densities[j]
            pressure_scale = (pressure_coeff * (h_minus_r * h_minus_r / distance)
                              * (densities[i] + densities[j] - DOUBLE_REST_DENSITY)
                              / density_product)
            viscosity_scale = viscosity_coeff * h_minus_r / density_product
            for axis in range(3):
                force = (disp[axis] * pressure_scale
                         + (velocities[j][axis] - velocities[i][axis]) * viscosity_scale)
                accelerations[i][axis] += force
                accelerations[j][axis] -= force
    output: list[float] = []
    for i in range(count):
        output.extend((densities[i], PRESSURE_STIFFNESS * (densities[i] - REST_DENSITY),
                       *accelerations[i]))
    return output


def expected_output(values: Sequence[int], output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_is_null or not _valid(values, input_length):
        return INVALID_RESULT, b""
    output_bytes = 40 * values[0]
    if output_is_null or output_capacity is None or output_capacity < output_bytes:
        return OUTPUT_ERROR, b""
    return output_bytes, struct.pack("<" + "d" * (5 * values[0]), *_compute_pairwise(values))

