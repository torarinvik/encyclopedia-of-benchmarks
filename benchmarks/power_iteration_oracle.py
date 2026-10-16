"""Oracle for the pinned Python real-valued power iteration path."""
import math
MAX_INPUT_LENGTH = 5
INVALID_RESULT = -1e300
MAX_ENTRY = 1000
ERROR_TOLERANCE = 1e-12
MAX_ITERATIONS = 100


def expected_result(values):
    if not isinstance(values, (list, tuple)) or len(values) != 5 or any(type(x) is not int for x in values):
        return INVALID_RESULT
    a, b, d, x, y = values
    if any(not 1 <= value <= MAX_ENTRY for value in values):
        return INVALID_RESULT
    if a * d <= b * b:
        return INVALID_RESULT
    vector = [float(x), float(y)]
    previous = 0.0
    iterations = 0
    while True:
        w0 = a * vector[0] + b * vector[1]
        w1 = b * vector[0] + d * vector[1]
        norm = math.sqrt(w0 * w0 + w1 * w1)
        if norm == 0.0:
            return INVALID_RESULT
        vector = [w0 / norm, w1 / norm]
        av0 = a * vector[0] + b * vector[1]
        av1 = b * vector[0] + d * vector[1]
        eigenvalue = vector[0] * av0 + vector[1] * av1
        error = abs(eigenvalue - previous) / eigenvalue
        iterations += 1
        if error <= ERROR_TOLERANCE or iterations >= MAX_ITERATIONS:
            return eigenvalue
        previous = eigenvalue

