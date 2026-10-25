"""Independent source-order oracle for the bounded FreeBench fbench core."""

from __future__ import annotations

import math
from typing import Sequence

INVALID_RESULT = -1e300
MAX_PASSES = 16

_SPECTRAL_LINE = {
    1: 7621.0,
    2: 6869.955,
    3: 6562.816,
    4: 5895.944,
    5: 5269.557,
    6: 4861.344,
    7: 4340.477,
    8: 3968.494,
}
_SURFACES = (
    (27.05, 1.5137, 63.6, 0.52),
    (-16.68, 1.0, 0.0, 0.138),
    (-16.68, 1.6164, 36.7, 0.38),
    (-78.1, 1.0, 0.0, 0.0),
)


def _trace_line(line: int, ray_height: float, paraxial: bool) -> tuple[float, float]:
    object_distance = 0.0
    axis_slope_angle = 0.0
    from_index = 1.0
    for surface_index, (radius, nominal_index, abbe_number, thickness) in enumerate(_SURFACES):
        to_index = nominal_index
        if to_index > 1.0:
            to_index += (
                (_SPECTRAL_LINE[4] - _SPECTRAL_LINE[line])
                / (_SPECTRAL_LINE[3] - _SPECTRAL_LINE[6])
            ) * ((nominal_index - 1.0) / abbe_number)

        if paraxial:
            if radius != 0.0:
                if object_distance == 0.0:
                    axis_slope_angle = 0.0
                    incidence_sine = ray_height / radius
                else:
                    incidence_sine = ((object_distance - radius) / radius) * axis_slope_angle
                refraction_sine = (from_index / to_index) * incidence_sine
                old_axis_slope_angle = axis_slope_angle
                axis_slope_angle = axis_slope_angle + incidence_sine - refraction_sine
                if object_distance != 0.0:
                    ray_height = object_distance * old_axis_slope_angle
                object_distance = ray_height / axis_slope_angle
            else:
                object_distance = object_distance * (to_index / from_index)
                axis_slope_angle = axis_slope_angle * (from_index / to_index)
        elif radius != 0.0:
            if object_distance == 0.0:
                axis_slope_angle = 0.0
                incidence_sine = ray_height / radius
            else:
                incidence_sine = ((object_distance - radius) / radius) * math.sin(axis_slope_angle)
            incidence_angle = math.asin(incidence_sine)
            refraction_sine = (from_index / to_index) * incidence_sine
            old_axis_slope_angle = axis_slope_angle
            axis_slope_angle = axis_slope_angle + incidence_angle - math.asin(refraction_sine)
            sagitta = math.sin((old_axis_slope_angle + incidence_angle) / 2.0)
            sagitta = 2.0 * radius * sagitta * sagitta
            object_distance = (
                (radius * math.sin(old_axis_slope_angle + incidence_angle))
                * (1.0 / math.tan(axis_slope_angle))
            ) + sagitta
        else:
            refraction_angle = -math.asin((from_index / to_index) * math.sin(axis_slope_angle))
            object_distance = object_distance * (
                (to_index * math.cos(-refraction_angle))
                / (from_index * math.cos(axis_slope_angle))
            )
            axis_slope_angle = -refraction_angle

        from_index = to_index
        if surface_index < len(_SURFACES) - 1:
            object_distance = object_distance - thickness
    return object_distance, axis_slope_angle


def _one_pass_projection(ray_height: float) -> float:
    paraxial_rays = [
        _trace_line(4, ray_height, False),
        _trace_line(4, ray_height, True),
    ]
    marginal_c = _trace_line(3, ray_height, False)[0]
    marginal_f = _trace_line(6, ray_height, False)[0]
    marginal_distance, marginal_angle = paraxial_rays[0]
    paraxial_distance, paraxial_angle = paraxial_rays[1]

    spherical_aberration = paraxial_distance - marginal_distance
    sine_condition_aberration = 1.0 - (
        (paraxial_distance * paraxial_angle)
        / (math.sin(marginal_angle) * marginal_distance)
    )
    chromatic_aberration = marginal_f - marginal_c
    return spherical_aberration + sine_condition_aberration + chromatic_aberration


def expected_result(values: Sequence[int]) -> float:
    """Return the accumulated aberration projection for a bounded pass count."""
    if len(values) != 1 or not isinstance(values[0], int) or not 1 <= values[0] <= MAX_PASSES:
        return INVALID_RESULT
    total = 0.0
    for pass_index in range(values[0]):
        ray_height = 2.0 + 0.0002 * pass_index
        total += _one_pass_projection(ray_height)
    return total
