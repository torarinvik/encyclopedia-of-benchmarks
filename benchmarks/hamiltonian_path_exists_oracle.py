"""Oracle for directed Hamiltonian-path existence on a packed matrix."""

from __future__ import annotations

MAX_VALID_VERTICES = 8
MAX_INPUT_LENGTH = 1 + MAX_VALID_VERTICES * MAX_VALID_VERTICES
INVALID_RESULT = -1

def expected_output(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1 for value in values)):
        return INVALID_RESULT
    n = values[0]
    if not 0 <= n <= MAX_VALID_VERTICES or len(values) != 1 + n * n:
        return INVALID_RESULT
    matrix = values[1:]
    if any(cell not in (0, 1) for cell in matrix):
        return INVALID_RESULT
    if n == 0:
        return 0
    routes = [0] * n
    for row in range(n):
        for column in range(n):
            if matrix[row * n + column]:
                routes[row] |= 1 << column
    full = (1 << n) - 1
    def extend(mask: int, last: int) -> bool:
        if mask == full:
            return True
        available = routes[last] & ~mask
        while available:
            bit = available & -available
            if extend(mask | bit, bit.bit_length() - 1):
                return True
            available -= bit
        return False
    return int(any(extend(1 << start, start) for start in range(n)))

expected_result = expected_output
