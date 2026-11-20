"""Full suffix-state exact-rational oracle for the bounded Penney profile."""

from fractions import Fraction

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


def _solve_exact(matrix: list[list[Fraction]], size: int) -> None:
    for column in range(size):
        pivot = next((row for row in range(column, size)
                      if matrix[row][column] != 0), None)
        if pivot is None:
            raise ArithmeticError("singular absorption system")
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        scale = matrix[column][column]
        matrix[column] = [value / scale for value in matrix[column]]
        for row in range(size):
            if row == column:
                continue
            factor = matrix[row][column]
            matrix[row] = [
                left - factor * right
                for left, right in zip(matrix[row], matrix[column])
            ]


def expected_result(values: list[int] | tuple[int, ...] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    word_length, first, second = parsed
    states = ["" if length == 0 else format(value, f"0{length}b")
              for length in range(word_length)
              for value in range(1 << length)]
    state_index = {state: index for index, state in enumerate(states)}
    size = len(states)
    matrix = [[Fraction(0) for _ in range(size + 1)] for _ in range(size)]

    for row, state in enumerate(states):
        matrix[row][row] = Fraction(2)
        for bit in "01":
            candidate = state + bit
            if len(candidate) == word_length and candidate == first:
                matrix[row][-1] += 1
                continue
            if len(candidate) == word_length and candidate == second:
                continue
            suffix = max(
                (candidate[-length:] if length else ""
                 for length in range(min(len(candidate), word_length - 1) + 1)),
                key=len,
            )
            matrix[row][state_index[suffix]] -= 1

    _solve_exact(matrix, size)
    probability = matrix[state_index[""]][-1]
    return (probability.numerator % MODULUS) * pow(probability.denominator, MODULUS - 2, MODULUS) % MODULUS


penney_game_pattern_probability = expected_result
