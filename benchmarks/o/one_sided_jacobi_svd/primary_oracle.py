"""Primary one-sided cyclic Jacobi singular-spectrum reference."""

from __future__ import annotations

from math import floor, sqrt

MAX_DIMENSION = 6
MAX_VALID_INPUT_LENGTH = 2 + MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_SWEEPS = 128
INVALID_RESULT = -1
ORTHOGONALITY_TOLERANCE = 1.0e-14
SIGNATURE_SCALE = 1000


def expected_result(values, input_is_null=False, input_length=None):
    if input_length is None:
        input_length = len(values)
    if input_is_null or values is None or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if len(values) < input_length:
        return INVALID_RESULT
    m, n = values[0], values[1]
    if not (1 <= n <= m <= MAX_DIMENSION) or input_length != 2 + m * n:
        return INVALID_RESULT
    matrix = values[2:input_length]
    if any(not isinstance(x, int) or x < -8 or x > 8 for x in matrix):
        return INVALID_RESULT

    columns = [[float(matrix[row * n + col]) for row in range(m)] for col in range(n)]
    converged = False
    for _ in range(MAX_SWEEPS):
        changed = False
        for p in range(n):
            for q in range(p + 1, n):
                alpha = sum(x * x for x in columns[p])
                beta = sum(x * x for x in columns[q])
                gamma = sum(x * y for x, y in zip(columns[p], columns[q]))
                if alpha == 0.0 or beta == 0.0:
                    continue
                if abs(gamma) <= ORTHOGONALITY_TOLERANCE * sqrt(alpha * beta):
                    continue
                tau = (beta - alpha) / (2.0 * gamma)
                t = 1.0 if tau == 0.0 else (1.0 if tau > 0.0 else -1.0) / (abs(tau) + sqrt(1.0 + tau * tau))
                c = 1.0 / sqrt(1.0 + t * t)
                s = c * t
                old_p, old_q = columns[p][:], columns[q][:]
                columns[p] = [c * x - s * y for x, y in zip(old_p, old_q)]
                columns[q] = [s * x + c * y for x, y in zip(old_p, old_q)]
                changed = True
        if not changed:
            converged = True
            break
    if not converged:
        return INVALID_RESULT

    singular_values = sorted((sqrt(sum(x * x for x in col)) for col in columns), reverse=True)
    signature = sum((index + 1) * value for index, value in enumerate(singular_values))
    return int(floor(SIGNATURE_SCALE * signature + 0.5))
