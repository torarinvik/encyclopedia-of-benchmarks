"""Independent affine-LCG oracle for the bounded Shootout random profile."""

from __future__ import annotations

MIN_CALL_COUNT = 1
MAX_CALL_COUNT = 1_000_000
MAX_OUTPUT_BYTES = 13
INVALID_RESULT = -1
OUTPUT_ERROR = -2

_MODULUS = 139_968
_MULTIPLIER = 3_877
_INCREMENT = 29_573
_INITIAL_STATE = 42
_FRACTION_SCALE = 1_000_000_000


def _state_after(call_count: int) -> int:
    """Apply the affine recurrence by exponentiating its transform."""
    accumulated_multiplier = 1
    accumulated_increment = 0
    power_multiplier = _MULTIPLIER
    power_increment = _INCREMENT
    exponent = call_count

    while exponent:
        if exponent & 1:
            accumulated_multiplier, accumulated_increment = (
                power_multiplier * accumulated_multiplier % _MODULUS,
                (power_multiplier * accumulated_increment + power_increment)
                % _MODULUS,
            )
        power_multiplier, power_increment = (
            power_multiplier * power_multiplier % _MODULUS,
            (power_multiplier * power_increment + power_increment) % _MODULUS,
        )
        exponent >>= 1

    return (accumulated_multiplier * _INITIAL_STATE + accumulated_increment) % _MODULUS


def expected_output(call_count: int) -> tuple[int, bytes]:
    """Return the exact nine-place decimal source output or the invalid sentinel."""
    if (type(call_count) is not int
            or not MIN_CALL_COUNT <= call_count <= MAX_CALL_COUNT):
        return INVALID_RESULT, b""

    state = _state_after(call_count)
    # The source value is 100*state/MODULUS. At nine places, its reduced
    # fractional denominator is odd, so it cannot lie exactly on a rounding tie.
    scaled = (100 * state * _FRACTION_SCALE + _MODULUS // 2) // _MODULUS
    whole, fraction = divmod(scaled, _FRACTION_SCALE)
    output = f"{whole}.{fraction:09d}\n".encode("ascii")
    return len(output), output
