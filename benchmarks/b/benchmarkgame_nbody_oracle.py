"""Scalar oracle for the bounded classic five-body Benchmark Game profile."""

from __future__ import annotations

import math
import struct

MAX_STEPS = 1000
MAX_INPUT_LENGTH = 2
OUTPUT_BYTES = 16
INVALID_RESULT = -1
OUTPUT_ERROR = -2

PI = 3.141592653589793
SOLAR_MASS = 4 * PI * PI
DAYS_PER_YEAR = 365.24
DT = 0.01

# Each row is x,y,z,vx,vy,vz,mass; the order and decimal constants follow n-body.c.
INITIAL_BODIES = (
    (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, SOLAR_MASS),
    (4.84143144246472090e+00, -1.16032004402742839e+00, -1.03622044471123109e-01,
     1.66007664274403694e-03 * DAYS_PER_YEAR, 7.69901118419740425e-03 * DAYS_PER_YEAR,
     -6.90460016972063023e-05 * DAYS_PER_YEAR, 9.54791938424326609e-04 * SOLAR_MASS),
    (8.34336671824457987e+00, 4.12479856412430479e+00, -4.03523417114321381e-01,
     -2.76742510726862411e-03 * DAYS_PER_YEAR, 4.99852801234917238e-03 * DAYS_PER_YEAR,
     2.30417297573763929e-05 * DAYS_PER_YEAR, 2.85885980666130812e-04 * SOLAR_MASS),
    (1.28943695621391310e+01, -1.51111514016986312e+01, -2.23307578892655734e-01,
     2.96460137564761618e-03 * DAYS_PER_YEAR, 2.37847173959480950e-03 * DAYS_PER_YEAR,
     -2.96589568540237556e-05 * DAYS_PER_YEAR, 4.36624404335156298e-05 * SOLAR_MASS),
    (1.53796971148509165e+01, -2.59193146099879641e+01, 1.79258772950371181e-01,
     2.68067772490389322e-03 * DAYS_PER_YEAR, 1.62824170038242295e-03 * DAYS_PER_YEAR,
     -9.51592254519715870e-05 * DAYS_PER_YEAR, 5.15138902046611451e-05 * SOLAR_MASS),
)


def _energy(bodies: list[list[float]]) -> float:
    energy = 0.0
    for i, body in enumerate(bodies):
        energy += 0.5 * body[6] * (body[3] * body[3] + body[4] * body[4] + body[5] * body[5])
        for j in range(i + 1, len(bodies)):
            other = bodies[j]
            dx = body[0] - other[0]
            dy = body[1] - other[1]
            dz = body[2] - other[2]
            distance = math.sqrt(dx * dx + dy * dy + dz * dz)
            energy -= (body[6] * other[6]) / distance
    return energy


def _simulate(steps: int) -> tuple[float, float]:
    bodies = [list(row) for row in INITIAL_BODIES]
    px = py = pz = 0.0
    for body in bodies:
        px += body[3] * body[6]
        py += body[4] * body[6]
        pz += body[5] * body[6]
    bodies[0][3] = -px / SOLAR_MASS
    bodies[0][4] = -py / SOLAR_MASS
    bodies[0][5] = -pz / SOLAR_MASS
    initial_energy = _energy(bodies)

    for _ in range(steps):
        for i in range(len(bodies)):
            body = bodies[i]
            for j in range(i + 1, len(bodies)):
                other = bodies[j]
                dx = body[0] - other[0]
                dy = body[1] - other[1]
                dz = body[2] - other[2]
                distance = math.sqrt(dx * dx + dy * dy + dz * dz)
                magnitude = DT / (distance * distance * distance)
                body[3] -= dx * other[6] * magnitude
                body[4] -= dy * other[6] * magnitude
                body[5] -= dz * other[6] * magnitude
                other[3] += dx * body[6] * magnitude
                other[4] += dy * body[6] * magnitude
                other[5] += dz * body[6] * magnitude
        for body in bodies:
            body[0] += DT * body[3]
            body[1] += DT * body[4]
            body[2] += DT * body[5]

    return initial_energy, _energy(bodies)


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_STEPS):
        return INVALID_RESULT, b""
    energies = _simulate(values[0])
    return OUTPUT_BYTES, struct.pack("<2d", *energies)
