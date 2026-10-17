"""Independent bounded oracle for the Maxwell scalar-method benchmark."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1e300
MAX_VALID_INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = 7

VACUUM_PERMITTIVITY = 8.8541878128e-12
VACUUM_PERMEABILITY = 4 * math.pi * 1e-7

PHYSICAL_RAW_SCALE = 1_000_000_000_000
CONSTANT_RAW_SCALE = 1_000_000_000_000_000_000
FLUX_RATE_RAW_SCALE = 1_000_000
MAX_PHYSICAL_RAW = 1_000_000_000_000_000
MAX_FLUX_RATE_RAW = 1_000_000_000_000_000_000
MIN_CONSTANT_RAW = 1_000_000
MAX_CONSTANT_RAW = 1_000_000_000_000_000


def _physical(raw: int) -> float:
    return raw / PHYSICAL_RAW_SCALE


def _optional_constant(raw: int, default: float) -> float | None:
    """Decode a positive custom constant, or select the exact source default."""
    if raw == 0:
        return default
    if not MIN_CONSTANT_RAW <= raw <= MAX_CONSTANT_RAW:
        return None
    return raw / CONSTANT_RAW_SCALE


def _bounded(raw: int, limit: int) -> bool:
    return -limit <= raw <= limit


def expected_result(values: Sequence[int] | None) -> float:
    """Evaluate one source method selected by its first packed integer.

    Malformed values, operation layouts, and domains return the benchmark's
    invalid sentinel. The returned Maxwell-law checks are binary64 0.0/1.0.
    """
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT

    operation = values[0]

    if operation == 0:
        if len(values) != 5:
            return INVALID_RESULT
        _, field_raw, area_raw, charge_raw, permittivity_raw = values
        if (not _bounded(field_raw, MAX_PHYSICAL_RAW)
                or not 0 <= area_raw <= MAX_PHYSICAL_RAW
                or not _bounded(charge_raw, MAX_PHYSICAL_RAW)):
            return INVALID_RESULT
        permittivity = _optional_constant(permittivity_raw, VACUUM_PERMITTIVITY)
        if permittivity is None:
            return INVALID_RESULT

        electric_flux = _physical(field_raw) * _physical(area_raw)
        expected_flux = _physical(charge_raw) / permittivity
        tolerance = 0.01 * abs(expected_flux) if expected_flux != 0 else 1e-10
        return float(abs(electric_flux - expected_flux) <= tolerance)

    if operation == 1:
        if len(values) != 3:
            return INVALID_RESULT
        _, circulation_raw, flux_rate_raw = values
        if (not _bounded(circulation_raw, MAX_PHYSICAL_RAW)
                or not _bounded(flux_rate_raw, MAX_PHYSICAL_RAW)):
            return INVALID_RESULT

        expected_circulation = -_physical(flux_rate_raw)
        tolerance = 0.01 * abs(expected_circulation) if expected_circulation != 0 else 1e-10
        return float(abs(_physical(circulation_raw) - expected_circulation) <= tolerance)

    if operation == 2:
        if len(values) != 6:
            return INVALID_RESULT
        _, circulation_raw, current_raw, flux_rate_raw, permeability_raw, permittivity_raw = values
        if (not _bounded(circulation_raw, MAX_PHYSICAL_RAW)
                or not _bounded(current_raw, MAX_PHYSICAL_RAW)
                or not _bounded(flux_rate_raw, MAX_FLUX_RATE_RAW)):
            return INVALID_RESULT
        permeability = _optional_constant(permeability_raw, VACUUM_PERMEABILITY)
        permittivity = _optional_constant(permittivity_raw, VACUUM_PERMITTIVITY)
        if permeability is None or permittivity is None:
            return INVALID_RESULT

        displacement_current = permittivity * (flux_rate_raw / FLUX_RATE_RAW_SCALE)
        total_current = _physical(current_raw) + displacement_current
        expected_circulation = permeability * total_current
        tolerance = 0.01 * abs(expected_circulation) if expected_circulation != 0 else 1e-10
        return float(abs(_physical(circulation_raw) - expected_circulation) <= tolerance)

    if operation in (3, 4):
        if len(values) != 3:
            return INVALID_RESULT
        _, permeability_raw, permittivity_raw = values
        permeability = _optional_constant(permeability_raw, VACUUM_PERMEABILITY)
        permittivity = _optional_constant(permittivity_raw, VACUUM_PERMITTIVITY)
        if permeability is None or permittivity is None:
            return INVALID_RESULT

        if operation == 3:
            return 1.0 / math.sqrt(permeability * permittivity)
        return math.sqrt(permeability / permittivity)

    if operation == 5:
        if len(values) != 4:
            return INVALID_RESULT
        _, electric_raw, magnetic_raw, permeability_raw = values
        if (not _bounded(electric_raw, MAX_PHYSICAL_RAW)
                or not _bounded(magnetic_raw, MAX_PHYSICAL_RAW)):
            return INVALID_RESULT
        permeability = _optional_constant(permeability_raw, VACUUM_PERMEABILITY)
        if permeability is None:
            return INVALID_RESULT

        # The source calls this a magnitude but returns the signed product.
        return (_physical(electric_raw) * _physical(magnetic_raw)) / permeability

    if operation == 6:
        if len(values) != 5:
            return INVALID_RESULT
        _, electric_raw, magnetic_raw, permittivity_raw, permeability_raw = values
        if (not _bounded(electric_raw, MAX_PHYSICAL_RAW)
                or not _bounded(magnetic_raw, MAX_PHYSICAL_RAW)):
            return INVALID_RESULT
        permittivity = _optional_constant(permittivity_raw, VACUUM_PERMITTIVITY)
        permeability = _optional_constant(permeability_raw, VACUUM_PERMEABILITY)
        if permittivity is None or permeability is None:
            return INVALID_RESULT

        electric_energy_density = 0.5 * permittivity * (_physical(electric_raw) ** 2)
        magnetic_energy_density = 0.5 * (_physical(magnetic_raw) ** 2) / permeability
        return electric_energy_density + magnetic_energy_density

    return INVALID_RESULT
