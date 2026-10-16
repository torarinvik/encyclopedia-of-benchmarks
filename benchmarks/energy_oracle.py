"""Oracle for the pinned Rust 55-unit energy conversion."""

from __future__ import annotations

SCALE = 1_000_000
MAX_VALUE_MICRO = 1_000_000_000_000
MAX_UNIT_CODE = 54
MAX_INPUT_LENGTH = 4  # admit one extra packed value for malformed-input coverage
INVALID_RESULT = -1.0e300
JOULES_PER_UNIT = (
    1.0,
    1000.0,
    1000000.0,
    1000000000.0,
    0.001,
    1.0e-6,
    1.0e-9,
    1.0e-18,
    1.0,
    3600.0,
    1000.0,
    3600000.0,
    3600000000.0,
    3600000000000.0,
    1.0,
    1.0e-7,
    1.0e-7,
    4186.8,
    4186800.0,
    4.1868,
    4186.8,
    4.184,
    4184.0,
    1.602176634e-19,
    1.602176634e-16,
    1.602176634e-13,
    1055.05585262,
    1054.3499999744,
    1055055852.62,
    1.3558179483,
    1.3558179483,
    0.112984829,
    0.112984829,
    0.0070615518,
    0.0070615518,
    0.04214011,
    2684519.5368856,
    2647795.5,
    9.8066499997,
    0.0980665,
    9.8066499997,
    0.00980665,
    9.80665e-5,
    105505600.0,
    105505600.0,
    105480400.0,
    12660670.23144,
    40197627984.822,
    6383087908.3509,
    4184000000.0,
    4184000000000.0,
    4.184e15,
    4.184e18,
    4.3597482e-18,
    2.1798741e-18
)


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    value_micro, from_unit, to_unit = values
    if (not -MAX_VALUE_MICRO <= value_micro <= MAX_VALUE_MICRO
            or not 0 <= from_unit <= MAX_UNIT_CODE
            or not 0 <= to_unit <= MAX_UNIT_CODE):
        return INVALID_RESULT

    value = value_micro / SCALE
    joules = value * JOULES_PER_UNIT[from_unit]
    return joules / JOULES_PER_UNIT[to_unit]
