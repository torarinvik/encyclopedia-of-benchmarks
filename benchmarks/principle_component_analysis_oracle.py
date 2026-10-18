"""Oracle for the bounded StandardScaler plus PCA Python routine."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_SAMPLES = 3
MAX_SAMPLES = 8
MIN_FEATURES = 2
MAX_FEATURES = 4
MIN_VALUE = -9
MAX_VALUE = 9
MAX_COMPONENTS = MAX_FEATURES
MAX_INPUT_LENGTH = 3 + MAX_SAMPLES * MAX_FEATURES
MAX_OUTPUT_LENGTH = 2 + MAX_SAMPLES * MAX_FEATURES + MAX_COMPONENTS
MAX_JACOBI_SWEEPS = 64
JACOBI_TOLERANCE = 1e-14
MIN_EIGENGAP = 1e-8
ABSOLUTE_TOLERANCE = 1e-8
RELATIVE_TOLERANCE = 1e-8
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _jacobi_eigenpairs(matrix: list[list[float]]) -> tuple[list[float], list[list[float]]] | None:
    """Diagonalize a small symmetric matrix with deterministic Jacobi sweeps."""
    n = len(matrix)
    values = [row[:] for row in matrix]
    vectors = [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]
    for _ in range(MAX_JACOBI_SWEEPS + 1):
        largest = max((abs(values[p][q]) for p in range(n) for q in range(p + 1, n)),
                      default=0.0)
        if largest <= JACOBI_TOLERANCE:
            break
        for p in range(n):
            for q in range(p + 1, n):
                apq = values[p][q]
                if abs(apq) <= JACOBI_TOLERANCE:
                    continue
                tau = (values[q][q] - values[p][p]) / (2.0 * apq)
                sign = 1.0 if tau >= 0.0 else -1.0
                t = sign / (abs(tau) + math.sqrt(1.0 + tau * tau))
                c = 1.0 / math.sqrt(1.0 + t * t)
                s = t * c
                app = values[p][p]
                aqq = values[q][q]
                values[p][p] = app - t * apq
                values[q][q] = aqq + t * apq
                values[p][q] = values[q][p] = 0.0
                for r in range(n):
                    if r != p and r != q:
                        arp = values[r][p]
                        arq = values[r][q]
                        values[r][p] = values[p][r] = c * arp - s * arq
                        values[r][q] = values[q][r] = s * arp + c * arq
                    vrp = vectors[r][p]
                    vrq = vectors[r][q]
                    vectors[r][p] = c * vrp - s * vrq
                    vectors[r][q] = s * vrp + c * vrq
    else:
        return None
    eigenpairs = [(values[index][index], [vectors[row][index] for row in range(n)])
                  for index in range(n)]
    eigenpairs.sort(key=lambda pair: -pair[0])
    return [pair[0] for pair in eigenpairs], [pair[1] for pair in eigenpairs]


def expected_result(values: Sequence[int | float] | None) -> list[float] | int:
    """Return row-major sklearn-style scores followed by explained variance ratios."""
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           or not float(value).is_integer() for value in values[:3]):
        return INVALID_RESULT
    samples, features, components = (int(value) for value in values[:3])
    if (not MIN_SAMPLES <= samples <= MAX_SAMPLES
            or not MIN_FEATURES <= features <= MAX_FEATURES
            or not 1 <= components <= min(samples, features)
            or samples <= features
            or len(values) != 3 + samples * features):
        return INVALID_RESULT
    raw: list[float] = []
    for value in values[3:]:
        if (type(value) not in (int, float) or not math.isfinite(float(value))
                or not float(value).is_integer() or not MIN_VALUE <= int(value) <= MAX_VALUE):
            return INVALID_RESULT
        raw.append(float(value))

    rows = [raw[row * features:(row + 1) * features] for row in range(samples)]
    means = [0.0] * features
    for row in rows:
        for column, value in enumerate(row):
            means[column] += value
    means = [value / samples for value in means]
    variances = [0.0] * features
    for row in rows:
        for column, value in enumerate(row):
            delta = value - means[column]
            variances[column] += delta * delta
    variances = [value / samples for value in variances]
    if any(value <= 0.0 or not math.isfinite(value) for value in variances):
        return INVALID_RESULT
    scales = [math.sqrt(value) for value in variances]
    standardized = [[(value - means[column]) / scales[column]
                     for column, value in enumerate(row)] for row in rows]

    # PCA centers the already standardized values a second time.
    pca_means = [0.0] * features
    for row in standardized:
        for column, value in enumerate(row):
            pca_means[column] += value
    pca_means = [value / samples for value in pca_means]
    centered = [[value - pca_means[column] for column, value in enumerate(row)]
                for row in standardized]
    covariance = [[0.0] * features for _ in range(features)]
    for i in range(features):
        for j in range(i, features):
            total = 0.0
            for row in centered:
                total += row[i] * row[j]
            value = total / (samples - 1)
            covariance[i][j] = covariance[j][i] = value
    result = _jacobi_eigenpairs(covariance)
    if result is None:
        return INVALID_RESULT
    eigenvalues, eigenvectors = result
    if (any(not math.isfinite(value) or value <= 0.0 for value in eigenvalues)
            or any(eigenvalues[index] - eigenvalues[index + 1] <= MIN_EIGENGAP
                   for index in range(features - 1))):
        return INVALID_RESULT
    total_variance = sum(eigenvalues)
    if not math.isfinite(total_variance) or total_variance <= 0.0:
        return INVALID_RESULT

    scores_by_component: list[list[float]] = []
    for vector in eigenvectors[:components]:
        component_scores = []
        for row in centered:
            score = 0.0
            for index in range(features):
                score += row[index] * vector[index]
            component_scores.append(score)
        # sklearn's full-SVD svd_flip uses the largest-magnitude U entry.
        pivot = max(range(samples), key=lambda index: abs(component_scores[index]))
        if component_scores[pivot] < 0.0:
            vector = [-value for value in vector]
            component_scores = [-value for value in component_scores]
        scores_by_component.append(component_scores)
    output = [float(samples), float(components)]
    for row in range(samples):
        for component in range(components):
            output.append(scores_by_component[component][row])
    output.extend(value / total_variance for value in eigenvalues[:components])
    if len(output) > MAX_OUTPUT_LENGTH or any(not math.isfinite(value) for value in output):
        return INVALID_RESULT
    return output


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, list[float]]:
    """Adapt the semantic oracle to the two-buffer slice ABI."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, []
    if input_is_null or values is None:
        return INVALID_RESULT, []
    output = expected_result(values)
    if type(output) is int:
        return output, []
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output
