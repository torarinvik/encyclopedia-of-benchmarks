"""Runtime oracle for bounded scalar-tensor FedAvg aggregation."""

INVALID_RESULT = -1e300
MAX_CLIENTS = 8
MAX_INPUT_LENGTH = 1 + 2 * MAX_CLIENTS


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 1
            or len(values) > MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return INVALID_RESULT
    count = values[0]
    if not 1 <= count <= MAX_CLIENTS or len(values) != 1 + 2 * count:
        return INVALID_RESULT
    weights = values[1:1 + count]
    model_values = values[1 + count:]
    if any(not 0 <= weight <= 1000 for weight in weights):
        return INVALID_RESULT
    if any(not -1000 <= value <= 1000 for value in model_values):
        return INVALID_RESULT
    total = float(sum(weights))
    if total <= 0.0:
        return INVALID_RESULT
    normalized = [weight / total for weight in weights]
    result = 0.0
    for weight, value in zip(normalized, model_values):
        result += weight * value
    return result
