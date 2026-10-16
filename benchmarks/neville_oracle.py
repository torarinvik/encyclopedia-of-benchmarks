"""Oracle for bounded Neville polynomial interpolation."""

MAX_INPUT_LENGTH = 34
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    count, target = values[:2]
    if not 1 <= count <= 16 or len(values) != 2 * count + 2 or not -1_000_000 <= target <= 1_000_000:
        return INVALID_RESULT
    x: list[float] = []
    p: list[float] = []
    for i in range(count):
        xi, yi = values[2 + 2 * i:4 + 2 * i]
        if not -1_000_000 <= xi <= 1_000_000 or not -1_000_000 <= yi <= 1_000_000 or xi in values[2:2 + 2 * i:2]:
            return INVALID_RESULT
        x.append(float(xi))
        p.append(float(yi))
    t = float(target)
    for k in range(1, count):
        for i in range(count - k):
            p[i] = ((t - x[i + k]) * p[i] + (x[i] - t) * p[i + 1]) / (x[i] - x[i + k])
    return p[0]
