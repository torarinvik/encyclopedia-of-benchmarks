"""Source-ordered oracle for the bounded Python Hubble parameter workload."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_INPUT_LENGTH = 5


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Evaluate the pinned expansion-rate formula for its integer encoding."""
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT

    h0_x10, radiation_ppm, matter_ppm, dark_energy_ppm, redshift_milli = values
    if (not -2000 <= h0_x10 <= 2000
            or any(not 0 <= density <= 1_000_000
                   for density in (radiation_ppm, matter_ppm, dark_energy_ppm))
            or radiation_ppm + matter_ppm + dark_energy_ppm > 1_000_000
            or not 0 <= redshift_milli <= 10_000):
        return INVALID_RESULT

    hubble_constant = h0_x10 / 10
    radiation = radiation_ppm / 1_000_000
    matter = matter_ppm / 1_000_000
    dark_energy = dark_energy_ppm / 1_000_000
    redshift = redshift_milli / 1_000
    curvature = 1 - (matter + radiation + dark_energy)
    e2 = (radiation * (redshift + 1) ** 4
          + matter * (redshift + 1) ** 3
          + curvature * (redshift + 1) ** 2
          + dark_energy)
    return hubble_constant * e2 ** (1 / 2)
