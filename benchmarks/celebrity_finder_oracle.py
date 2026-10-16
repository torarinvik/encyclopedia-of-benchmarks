"""Independent direct-definition oracle for the celebrity finder benchmark."""

from __future__ import annotations

MAX_PERSON_COUNT = 64
MAX_INPUT_LENGTH = 1 + MAX_PERSON_COUNT * MAX_PERSON_COUNT
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def expected_result(values: list[int]) -> int:
    """Return the zero-based celebrity, -1 if absent, or -2 for malformed input.

    The pinned Java implementation uses stack elimination followed by
    verification. This oracle checks the definition directly for every person
    so it does not reuse that candidate-elimination recurrence.
    """
    if (not isinstance(values, list) or not values or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -2

    person_count = values[0]
    if (not 1 <= person_count <= MAX_PERSON_COUNT
            or len(values) != 1 + person_count * person_count
            or any(value not in (0, 1) for value in values[1:])):
        return -2

    matrix = values[1:]
    for candidate in range(person_count):
        knows_nobody = all(
            matrix[candidate * person_count + other] == 0
            for other in range(person_count) if other != candidate
        )
        known_by_everyone = all(
            matrix[other * person_count + candidate] == 1
            for other in range(person_count) if other != candidate
        )
        if knows_nobody and known_by_everyone:
            return candidate
    return -1
