"""Independent symmetric-Jacobi eigensolver reference for singular values."""

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
    entries = values[2:input_length]
    if any(not isinstance(x, int) or x < -8 or x > 8 for x in entries):
        return INVALID_RESULT

    gram = [[0.0] * n for _ in range(n)]
    for i in range(n):
        for j in range(n):
            gram[i][j] = float(sum(entries[row * n + i] * entries[row * n + j] for row in range(m)))

    converged = False
    for _ in range(MAX_SWEEPS):
        changed = False
        for p in range(n):
            for q in range(p + 1, n):
                alpha, beta, gamma = gram[p][p], gram[q][q], gram[p][q]
                if alpha <= 0.0 or beta <= 0.0:
                    continue
                if abs(gamma) <= ORTHOGONALITY_TOLERANCE * sqrt(alpha * beta):
                    continue
                tau = (beta - alpha) / (2.0 * gamma)
                t = 1.0 if tau == 0.0 else (1.0 if tau > 0.0 else -1.0) / (abs(tau) + sqrt(1.0 + tau * tau))
                c = 1.0 / sqrt(1.0 + t * t)
                s = c * t
                for k in range(n):
                    if k == p or k == q:
                        continue
                    x, y = gram[k][p], gram[k][q]
                    gram[k][p] = gram[p][k] = c * x - s * y
                    gram[k][q] = gram[q][k] = s * x + c * y
                gram[p][p] = alpha - t * gamma
                gram[q][q] = beta + t * gamma
                gram[p][q] = gram[q][p] = 0.0
                changed = True
        if not changed:
            converged = True
            break
    if not converged:
        return INVALID_RESULT

    singular_values = sorted((sqrt(max(0.0, gram[i][i])) for i in range(n)), reverse=True)
    signature = sum((index + 1) * value for index, value in enumerate(singular_values))
    return int(floor(SIGNATURE_SCALE * signature + 0.5))
