"""Bounded oracle for the pinned Rust gradient-descent square-function test."""
INVALID_RESULT = -1e300
MAX_DIMENSION = 64
MAX_ITERATIONS = 10_000

def expected_result(values: list[int]) -> float:
    if len(values) < 5 or len(values) > 68:
        return INVALID_RESULT
    dimension, selected, rate, iterations = values[:4]
    if (not 1 <= dimension <= MAX_DIMENSION or not 0 <= selected < dimension
            or len(values) != 4 + dimension or not 1 <= rate <= 500_000
            or not 0 <= iterations <= MAX_ITERATIONS
            or any(not -10 <= item <= 10 for item in values[4:])):
        return INVALID_RESULT
    x = [float(item) for item in values[4:]]
    learning_rate = rate / 1_000_000.0
    for _ in range(iterations):
        gradient = [2.0 * value for value in x]
        for index, grad in enumerate(gradient):
            x[index] -= learning_rate * grad
    return x[selected]
