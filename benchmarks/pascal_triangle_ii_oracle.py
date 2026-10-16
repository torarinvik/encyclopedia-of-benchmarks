"""Binomial-coefficient oracle for the zero-based Pascal row benchmark."""
MAX_ROW = 30
MODULUS = 1_000_000_007
I64_MIN = -(1 << 63)

def expected_result(row: int) -> int:
    if type(row) is not int or not 0 <= row <= MAX_ROW:
        return I64_MIN
    coefficient = 1
    result = 0
    for column in range(row + 1):
        result = (result * 31 + coefficient) % MODULUS
        if column < row:
            coefficient = coefficient * (row - column) // (column + 1)
    return result
