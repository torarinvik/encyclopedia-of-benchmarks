"""Independent oracle for the bounded Doppler frequency benchmark."""

from __future__ import annotations

INVALID_RESULT = -1e300
MIN_ORIGINAL_FREQUENCY = 1
MAX_ORIGINAL_FREQUENCY = 1_000
MIN_WAVE_SPEED = 200
MAX_WAVE_SPEED = 1_000
MIN_VELOCITY = -100
MAX_VELOCITY = 100
MAX_INPUT_LENGTH = 5  # permits one extra value to reach the ABI as malformed input


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Evaluate the source-ordered Doppler formula for a validated input."""
    if (not isinstance(values, (list, tuple)) or len(values) != 4
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT

    original_frequency, wave_speed, observer_velocity, source_velocity = values
    if (not MIN_ORIGINAL_FREQUENCY <= original_frequency <= MAX_ORIGINAL_FREQUENCY
            or not MIN_WAVE_SPEED <= wave_speed <= MAX_WAVE_SPEED
            or not MIN_VELOCITY <= observer_velocity <= MAX_VELOCITY
            or not MIN_VELOCITY <= source_velocity <= MAX_VELOCITY):
        return INVALID_RESULT

    return (original_frequency * (wave_speed + observer_velocity)) / (wave_speed - source_velocity)
