"""Independent exact oracle for bounded C# decision convolutions."""

MAX_DECISIONS = 64
MAX_CRITERIA = 16
MAX_VALUE = 100_000  # decimal thousandths, or +/-100.000
MAX_INPUT_LENGTH = 3 + MAX_CRITERIA + MAX_DECISIONS * MAX_CRITERIA
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH):
        return INVALID_RESULT
    if any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values):
        return INVALID_RESULT
    method, decisions, criteria = values[:3]
    if method not in (0, 1) or not 1 <= decisions <= MAX_DECISIONS or not 1 <= criteria <= MAX_CRITERIA:
        return INVALID_RESULT
    if len(values) != 3 + criteria + decisions * criteria:
        return INVALID_RESULT
    priorities = values[3 : 3 + criteria]
    matrix = values[3 + criteria :]
    if any(abs(value) > MAX_VALUE for value in priorities + matrix):
        return INVALID_RESULT

    best_index = 0
    best_score: int | None = None
    for row_index in range(decisions):
        row = matrix[row_index * criteria : (row_index + 1) * criteria]
        products = [value * weight for value, weight in zip(row, priorities)]
        score = sum(products) if method == 0 else min(products)
        if best_score is None or score > best_score:
            best_score = score
            best_index = row_index
    return best_index
