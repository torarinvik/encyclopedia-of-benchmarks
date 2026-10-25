"""Independent, pull-based oracle for the bounded Parboil D3Q19 step."""

from __future__ import annotations

from collections.abc import Sequence
import struct

Q = 19
MAX_INPUT_LENGTH = Q
MAX_PARSEABLE_INPUT_LENGTH = Q
MAX_POPULATION_RAW = 100_000
SCALE = 1_000_000
INVALID_RESULT = -1

_DIRECTIONS = (
    (0, 0, 0), (0, 1, 0), (0, -1, 0), (1, 0, 0), (-1, 0, 0),
    (0, 0, 1), (0, 0, -1), (1, 1, 0), (-1, 1, 0), (1, -1, 0),
    (-1, -1, 0), (0, 1, 1), (0, 1, -1), (0, -1, 1), (0, -1, -1),
    (1, 0, 1), (1, 0, -1), (-1, 0, 1), (-1, 0, -1),
)
_OPPOSITE = (0, 2, 1, 4, 3, 6, 5, 10, 9, 8, 7, 14, 13, 12, 11, 18, 17, 16, 15)


def _f32(value: int | float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _initial(q: int) -> float:
    if q == 0:
        return _f32(1.0 / 3.0)
    if q <= 6:
        return _f32(1.0 / 18.0)
    return _f32(1.0 / 36.0)


def _axis_factor(u: float, positive: bool, u2: float) -> float:
    product = _f32(_f32(4.5) * u)
    product = _f32(product + (_f32(3.0) if positive else _f32(-3.0)))
    product = _f32(u * product)
    product = _f32(_f32(1.0) + product)
    return _f32(product - u2)


def _diagonal_factor(cu: float, u2: float) -> float:
    product = _f32(_f32(4.5) * cu)
    product = _f32(product + _f32(3.0))
    product = _f32(cu * product)
    product = _f32(_f32(1.0) + product)
    return _f32(product - u2)


def _collide(source: float, rho: float, factor: float, weight: float) -> float:
    omega = _f32(1.95)
    base = _f32(_f32(_f32(1.0) - omega) * source)
    # DFL1/2/3 are unsuffixed double macros in the pinned C source.  Their
    # product with OMEGA, rho, and the already-f32 polynomial is binary64.
    equilibrium = weight * float(omega)
    equilibrium = equilibrium * float(rho)
    equilibrium = equilibrium * float(factor)
    return _f32(float(base) + equilibrium)


def _collide_center(populations: Sequence[float]) -> list[float]:
    rho = populations[0]
    for value in populations[1:]:
        rho = _f32(rho + value)

    ux = populations[3]
    for operation, value in (
        ("-", populations[4]), ("+", populations[7]), ("-", populations[8]),
        ("+", populations[9]), ("-", populations[10]), ("+", populations[15]),
        ("+", populations[16]), ("-", populations[17]), ("-", populations[18]),
    ):
        ux = _f32(ux + value if operation == "+" else ux - value)
    uy = populations[1]
    for operation, value in (
        ("-", populations[2]), ("+", populations[7]), ("+", populations[8]),
        ("-", populations[9]), ("-", populations[10]), ("+", populations[11]),
        ("+", populations[12]), ("-", populations[13]), ("-", populations[14]),
    ):
        uy = _f32(uy + value if operation == "+" else uy - value)
    uz = populations[5]
    for operation, value in (
        ("-", populations[6]), ("+", populations[11]), ("-", populations[12]),
        ("+", populations[13]), ("-", populations[14]), ("+", populations[15]),
        ("-", populations[16]), ("+", populations[17]), ("-", populations[18]),
    ):
        uz = _f32(uz + value if operation == "+" else uz - value)
    ux, uy, uz = _f32(ux / rho), _f32(uy / rho), _f32(uz / rho)

    u2 = _f32(ux * ux)
    u2 = _f32(u2 + _f32(uy * uy))
    u2 = _f32(u2 + _f32(uz * uz))
    u2 = _f32(_f32(1.5) * u2)

    factors = [_f32(_f32(1.0) - u2)]
    factors.extend((
        _axis_factor(uy, True, u2), _axis_factor(uy, False, u2),
        _axis_factor(ux, True, u2), _axis_factor(ux, False, u2),
        _axis_factor(uz, True, u2), _axis_factor(uz, False, u2),
    ))
    for a, b in (
        (ux, uy), (-ux, uy), (ux, -uy), (-ux, -uy),
        (uy, uz), (uy, -uz), (-uy, uz), (-uy, -uz),
        (ux, uz), (ux, -uz), (-ux, uz), (-ux, -uz),
    ):
        factors.append(_diagonal_factor(_f32(a + b), u2))

    result = []
    for q, factor in enumerate(factors):
        weight = (1.0 / 3.0) if q == 0 else ((1.0 / 18.0) if q <= 6 else (1.0 / 36.0))
        result.append(_collide(populations[q], rho, factor, weight))
    return result


def _quantize(value: float) -> int:
    scaled = _f32(_f32(value) * _f32(SCALE))
    magnitude = abs(scaled)
    whole = int(magnitude)
    if magnitude - _f32(whole) >= 0.5:
        whole += 1
    return -whole if scaled < 0.0 else whole


def _run(values: Sequence[int]) -> int:
    center = [_f32(_f32(raw) / _f32(SCALE)) for raw in values]
    post = _collide_center(center)
    checksum = 0

    # Gather each result from its unique streaming predecessor.  This is an
    # independently structured pull formulation of the source's push stores.
    for z in range(3):
        for y in range(3):
            for x in range(3):
                cell = x + 3 * y + 9 * z
                for q, (dx, dy, dz) in enumerate(_DIRECTIONS):
                    px, py, pz = x - dx, y - dy, z - dz
                    if not (0 <= px < 3 and 0 <= py < 3 and 0 <= pz < 3):
                        outgoing = _initial(q)  # the one-step destination began at equilibrium
                    else:
                        source_is_obstacle = px in (0, 2) or py in (0, 2) or pz in (0, 2)
                        if source_is_obstacle:
                            outgoing = _initial(_OPPOSITE[q])
                        else:
                            outgoing = post[q]
                    checksum += (cell + 1) * _quantize(outgoing)
    return checksum


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the one-step weighted population checksum or ``-1``."""
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) != Q
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not 0 <= value <= MAX_POPULATION_RAW for value in values)
            or not any(values)):
        return INVALID_RESULT
    return _run(values)


oracle = expected_result
