"""Independent bounded model of Rodinia's single-cell Euler3D flux kernel."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

INPUT_LENGTH = 41
INVALID_RESULT = -1
SCALE = 1_000
GAMMA = struct.unpack("<f", struct.pack("<f", 1.4))[0]
SMOOTHING = struct.unpack("<f", struct.pack("<f", 0.2))[0]


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _bits_f32(bits: int) -> float:
    return struct.unpack("<f", struct.pack("<I", bits))[0]


def _add(a: float, b: float) -> float:
    return _f32(a + b)


def _sub(a: float, b: float) -> float:
    return _f32(a - b)


def _mul(a: float, b: float) -> float:
    return _f32(a * b)


def _div(a: float, b: float) -> float:
    return _f32(a / b)


def _sqrt(a: float) -> float:
    return _f32(math.sqrt(a))


def _finite(value: float) -> bool:
    return math.isfinite(value)


def _state_from_bits(bits: Sequence[int]) -> tuple[float, float, float, float, float] | None:
    state = tuple(_bits_f32(value) for value in bits)
    density, mx, my, mz, energy = state
    if (not all(_finite(value) for value in state) or not (0.5 <= density <= 2.0)
            or max(abs(mx), abs(my), abs(mz)) > 1.0 or not (1.0 <= energy <= 5.0)):
        return None
    velocity = (_div(mx, density), _div(my, density), _div(mz, density))
    speed_squared = _add(_add(_mul(velocity[0], velocity[0]), _mul(velocity[1], velocity[1])),
                         _mul(velocity[2], velocity[2]))
    kinetic = _mul(_mul(_f32(0.5), density), speed_squared)
    pressure = _mul(_sub(GAMMA, _f32(1.0)), _sub(energy, kinetic))
    if not _finite(pressure) or pressure <= 0.0:
        return None
    return state  # type: ignore[return-value]


def _flow(state: tuple[float, float, float, float, float]) -> tuple[
    tuple[float, float, float], float, float, float,
    tuple[tuple[float, float, float], ...], tuple[float, float, float]
]:
    density, mx, my, mz, energy = state
    momentum = (mx, my, mz)
    velocity = (_div(mx, density), _div(my, density), _div(mz, density))
    speed_squared = _add(_add(_mul(velocity[0], velocity[0]), _mul(velocity[1], velocity[1])),
                         _mul(velocity[2], velocity[2]))
    speed = _sqrt(speed_squared)
    pressure = _mul(_sub(GAMMA, _f32(1.0)),
                    _sub(energy, _mul(_mul(_f32(0.5), density), speed_squared)))
    sound = _sqrt(_div(_mul(GAMMA, pressure), density))
    energy_plus_pressure = _add(energy, pressure)
    momentum_flux = (
        (_add(_mul(velocity[0], mx), pressure), _mul(velocity[0], my), _mul(velocity[0], mz)),
        (_mul(velocity[1], mx), _add(_mul(velocity[1], my), pressure), _mul(velocity[1], mz)),
        (_mul(velocity[2], mx), _mul(velocity[2], my), _add(_mul(velocity[2], mz), pressure)),
    )
    energy_flux = (_mul(velocity[0], energy_plus_pressure),
                   _mul(velocity[1], energy_plus_pressure),
                   _mul(velocity[2], energy_plus_pressure))
    return momentum, speed, sound, pressure, momentum_flux, energy_flux


def _farfield() -> tuple[tuple[float, float, float, float, float], tuple[float, float, float],
                         float, float, tuple[tuple[float, float, float], ...], tuple[float, float, float]]:
    density = _f32(1.4)
    pressure = _f32(1.0)
    sound = _sqrt(_div(_mul(GAMMA, pressure), density))
    speed = _mul(_f32(1.2), sound)
    velocity = (speed, _f32(0.0), _f32(0.0))
    momentum = (_mul(density, velocity[0]), _mul(density, velocity[1]), _mul(density, velocity[2]))
    density_energy = _add(
        _mul(density, _mul(_f32(0.5), _mul(speed, speed))),
        _div(pressure, _sub(GAMMA, _f32(1.0))),
    )
    state = (density, momentum[0], momentum[1], momentum[2], density_energy)
    mom_flux = (
        (_add(_mul(velocity[0], momentum[0]), pressure), _mul(velocity[0], momentum[1]), _mul(velocity[0], momentum[2])),
        (_mul(velocity[1], momentum[0]), _add(_mul(velocity[1], momentum[1]), pressure), _mul(velocity[1], momentum[2])),
        (_mul(velocity[2], momentum[0]), _mul(velocity[2], momentum[1]), _add(_mul(velocity[2], momentum[2]), pressure)),
    )
    de_p = _add(density_energy, pressure)
    energy_flux = (_mul(velocity[0], de_p), _mul(velocity[1], de_p), _mul(velocity[2], de_p))
    return state, momentum, speed, sound, mom_flux, energy_flux


def _round_away(value: float) -> int:
    scaled = value * SCALE
    return math.floor(scaled + 0.5) if scaled >= 0.0 else -math.floor(-scaled + 0.5)


def expected_result(values: Sequence[int] | None) -> int:
    """Compute one source-ordered four-face flux and project its five components."""
    if (not isinstance(values, (tuple, list)) or len(values) != INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    for index, value in enumerate(values):
        if index >= 5 and (index - 5) % 9 == 0:
            if value not in (-2, -1, 0):
                return INVALID_RESULT
        elif value < 0 or value > 0xFFFFFFFF:
            return INVALID_RESULT
    center = _state_from_bits(values[:5])
    if center is None:
        return INVALID_RESULT
    normals: list[tuple[float, float, float]] = []
    kinds: list[int] = []
    neighbors: list[tuple[float, float, float, float, float]] = []
    for face in range(4):
        at = 5 + 9 * face
        kind = values[at]
        if kind not in (-2, -1, 0):
            return INVALID_RESULT
        normal_bits = values[at + 1:at + 4]
        neighbor_bits = values[at + 4:at + 9]
        if any(bit < 0 or bit > 0xFFFFFFFF for bit in (*normal_bits, *neighbor_bits)):
            return INVALID_RESULT
        normal = tuple(_bits_f32(bit) for bit in normal_bits)
        if not all(_finite(component) and abs(component) <= 1.0 for component in normal):
            return INVALID_RESULT
        normals.append(normal)  # type: ignore[arg-type]
        kinds.append(kind)
        neighbor = _state_from_bits(neighbor_bits)
        if neighbor is None:
            return INVALID_RESULT
        neighbors.append(neighbor)

    density_i = center[0]
    momentum_i, speed_i, sound_i, pressure_i, momentum_flux_i, energy_flux_i = _flow(center)
    flux_density = _f32(0.0)
    flux_momentum = [_f32(0.0), _f32(0.0), _f32(0.0)]
    flux_energy = _f32(0.0)
    ff_state, ff_momentum, _, _, ff_momentum_flux, ff_energy_flux = _farfield()
    for face in range(4):
        kind = kinds[face]
        nx, ny, nz = normals[face]
        normal_len = _sqrt(_add(_add(_mul(nx, nx), _mul(ny, ny)), _mul(nz, nz)))
        if kind == 0:
            neighbor = neighbors[face]
            density_nb = neighbor[0]
            momentum_nb, _, sound_nb, _, momentum_flux_nb, energy_flux_nb = _flow(neighbor)
            velocity_nb = (_div(momentum_nb[0], density_nb), _div(momentum_nb[1], density_nb),
                           _div(momentum_nb[2], density_nb))
            speed_squared_nb = _add(_add(_mul(velocity_nb[0], velocity_nb[0]),
                                          _mul(velocity_nb[1], velocity_nb[1])),
                                    _mul(velocity_nb[2], velocity_nb[2]))
            factor = _mul(_mul(_mul(-normal_len, SMOOTHING), _f32(0.5)),
                          _add(_add(_add(speed_i, _sqrt(speed_squared_nb)), sound_i), sound_nb))
            flux_density = _add(flux_density, _mul(factor, _sub(density_i, density_nb)))
            flux_energy = _add(flux_energy, _mul(factor, _sub(center[4], neighbor[4])))
            for component in range(3):
                flux_momentum[component] = _add(
                    flux_momentum[component], _mul(factor, _sub(momentum_i[component], momentum_nb[component])))

            for axis, normal in enumerate((nx, ny, nz)):
                factor = _mul(_f32(0.5), normal)
                flux_density = _add(flux_density, _mul(factor, _add(momentum_nb[axis], momentum_i[axis])))
                flux_energy = _add(
                    flux_energy, _mul(factor, _add(energy_flux_nb[axis], energy_flux_i[axis])))
                for component in range(3):
                    flux_momentum[component] = _add(
                        flux_momentum[component],
                        _mul(factor, _add(momentum_flux_nb[axis][component], momentum_flux_i[axis][component])))
        elif kind == -1:
            for component, normal in enumerate((nx, ny, nz)):
                flux_momentum[component] = _add(flux_momentum[component], _mul(normal, pressure_i))
        else:
            for axis, normal in enumerate((nx, ny, nz)):
                factor = _mul(_f32(0.5), normal)
                flux_density = _add(flux_density, _mul(factor, _add(ff_momentum[axis], momentum_i[axis])))
                flux_energy = _add(flux_energy, _mul(factor, _add(ff_energy_flux[axis], energy_flux_i[axis])))
                for component in range(3):
                    flux_momentum[component] = _add(
                        flux_momentum[component],
                        _mul(factor, _add(ff_momentum_flux[axis][component], momentum_flux_i[axis][component])))

    result = [flux_density, *flux_momentum, flux_energy]
    if not all(_finite(value) for value in result):
        return INVALID_RESULT
    return sum((component + 1) * _round_away(value) for component, value in enumerate(result))
