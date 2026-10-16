"""Independent exact-rational oracle for the bounded Boyle's law benchmark."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_SUPPLIED_VALUE = 1_000
DECIMAL_SCALE = 1_000


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Solve the selected variable and round the quotient to three decimals, ties-to-even."""
    if (not isinstance(values, (list, tuple)) or len(values) != 4
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    missing_index = values[0]
    supplied = values[1:]
    if (not 0 <= missing_index <= 3
            or any(not 1 <= value <= MAX_SUPPLIED_VALUE for value in supplied)):
        return INVALID_RESULT

    variables: list[int | None] = []
    supplied_index = 0
    for variable_index in range(4):
        if variable_index == missing_index:
            variables.append(None)
        else:
            variables.append(supplied[supplied_index])
            supplied_index += 1

    if missing_index in (0, 2):
        numerator = variables[3] * variables[1]
        denominator = variables[2] if missing_index == 0 else variables[0]
    else:
        numerator = variables[2] * variables[0]
        denominator = variables[3] if missing_index == 1 else variables[1]
    assert isinstance(numerator, int) and isinstance(denominator, int)

    rounded, remainder = divmod(numerator * DECIMAL_SCALE, denominator)
    comparison = 2 * remainder - denominator
    if comparison > 0 or (comparison == 0 and rounded % 2 == 1):
        rounded += 1
    return rounded / DECIMAL_SCALE
