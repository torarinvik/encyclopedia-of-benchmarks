"""Fixed-label cycle recurrence for the bounded cycle-cap permutation count."""

MAX_N = 20
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: list[int] | tuple[int, ...] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    n, cap = values
    if not 1 <= n <= MAX_N or not 1 <= cap <= n:
        return None
    return n, cap


def _count_by_first_cycle(n: int, cap: int) -> int:
    counts = [0] * (n + 1)
    counts[0] = 1
    for size in range(1, n + 1):
        total = 0
        cycle_choices = 1
        for cycle_length in range(1, min(size, cap) + 1):
            if cycle_length > 1:
                cycle_choices *= size - cycle_length + 1
            total += cycle_choices * counts[size - cycle_length]
        counts[size] = total
    return counts[n]


def expected_result(values: list[int] | tuple[int, ...] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, cap = parsed
    return _count_by_first_cycle(n, cap)


random_permutation_cycle_cap_count = expected_result
