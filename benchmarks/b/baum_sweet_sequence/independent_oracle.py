"""Independent binary-string zero-run oracle for OEIS A086747 prefixes."""

from __future__ import annotations

from collections.abc import Sequence

MAX_COUNT = 63
INVALID_RESULT = -1


def _term_by_runs(number: int) -> int:
    binary = format(number, "b")
    run_length = 0
    for digit in binary:
        if digit == "0":
            run_length += 1
        else:
            if run_length % 2:
                return 0
            run_length = 0
    return int(run_length % 2 == 0)


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) != 1
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return INVALID_RESULT
    count = values[0]
    if not 0 <= count <= MAX_COUNT:
        return INVALID_RESULT
    return sum(_term_by_runs(number) << number for number in range(count))
