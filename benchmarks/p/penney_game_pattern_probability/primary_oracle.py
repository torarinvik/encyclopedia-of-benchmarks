"""Prefix-automaton reference for the bounded Penney game profile."""

MODULUS = 998_244_353
MAX_WORD_LENGTH = 4
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: list[int] | tuple[int, ...] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, str, str] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    word_length, first_mask, second_mask = values
    if not 1 <= word_length <= MAX_WORD_LENGTH:
        return None
    limit = 1 << word_length
    if not (0 <= first_mask < limit and 0 <= second_mask < limit):
        return None
    if first_mask == second_mask:
        return None
    return (word_length, f"{first_mask:0{word_length}b}", f"{second_mask:0{word_length}b}")


def _solve_modular(matrix: list[list[int]], size: int) -> None:
    for column in range(size):
        pivot = next((row for row in range(column, size)
                      if matrix[row][column] % MODULUS), None)
        if pivot is None:
            raise ArithmeticError("singular absorption system")
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        inverse = pow(matrix[column][column] % MODULUS, MODULUS - 2, MODULUS)
        matrix[column] = [value * inverse % MODULUS for value in matrix[column]]
        for row in range(size):
            if row == column:
                continue
            factor = matrix[row][column] % MODULUS
            matrix[row] = [
                (left - factor * right) % MODULUS
                for left, right in zip(matrix[row], matrix[column])
            ]


def expected_result(values: list[int] | tuple[int, ...] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    word_length, first, second = parsed
    states = [""]
    for pattern in (first, second):
        for prefix_length in range(1, word_length):
            prefix = pattern[:prefix_length]
            if prefix not in states:
                states.append(prefix)

    matrix = [[0] * (len(states) + 1) for _ in states]
    for row, state in enumerate(states):
        matrix[row][row] = 2
        for bit in "01":
            candidate = state + bit
            if len(candidate) == word_length and candidate == first:
                matrix[row][-1] += 1
                continue
            if len(candidate) == word_length and candidate == second:
                continue
            destination = max(
                (index for index, suffix in enumerate(states)
                 if candidate.endswith(suffix)),
                key=lambda index: len(states[index]),
            )
            matrix[row][destination] -= 1

    _solve_modular(matrix, len(states))
    return matrix[0][-1] % MODULUS


penney_game_pattern_probability = expected_result
