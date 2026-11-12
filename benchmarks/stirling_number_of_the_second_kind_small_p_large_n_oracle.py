"""Fixed-width transition-matrix oracle for bounded large-n Stirling values."""

MODULUS_MIN = 11
MODULUS_MAX = 97
MAX_T = 8
MAX_K = 8
MAX_N = 1_000_000_000_000_000_000
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_T
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
INVALID_RESULT = -1


def is_prime(value):
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def stirling_value_by_matrix(n, k, modulus):
    """Return S(n,k) by exponentiating the k+1 state recurrence."""
    width = k + 1
    matrix = [[0] * width for _ in range(width)]
    for index in range(width):
        matrix[index][index] = index % modulus
        if index > 0:
            matrix[index][index - 1] = 1
    vector = [0] * width
    vector[0] = 1
    exponent = n
    while exponent:
        if exponent & 1:
            vector = [
                sum(matrix[row][column] * vector[column]
                    for column in range(width)) % modulus
                for row in range(width)
            ]
        exponent >>= 1
        if exponent:
            matrix = [
                [sum(matrix[row][inner] * matrix[inner][column]
                     for inner in range(width)) % modulus
                 for column in range(width)]
                for row in range(width)
            ]
    return vector[k]


def expected_result(values):
    if (not isinstance(values, (list, tuple))
            or len(values) < 4
            or len(values) > MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    count, modulus = values[:2]
    if (not 1 <= count <= MAX_T
            or len(values) != 2 + 2 * count
            or not MODULUS_MIN <= modulus <= MODULUS_MAX
            or not is_prime(modulus)):
        return INVALID_RESULT
    answer = 0
    for case_index in range(count):
        n, k = values[2 + 2 * case_index:4 + 2 * case_index]
        if not 0 <= n <= MAX_N or not 0 <= k <= min(n, MAX_K):
            return INVALID_RESULT
        value = stirling_value_by_matrix(n, k, modulus)
        answer = (answer + (case_index + 1) ** 2 * value) % modulus
    return answer
