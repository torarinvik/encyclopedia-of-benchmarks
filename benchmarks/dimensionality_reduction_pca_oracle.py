"""Oracle for the bounded one-component slice of Python dimensionality_reduction."""
import math

BAD = -1e300
MAX_SAMPLES = 8


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 7
            or any(type(x) not in (int, float) or not math.isfinite(float(x)) for x in values)):
        return None
    if any(abs(float(x)) > 1_000_000 for x in values[3:]):
        return None
    if values[0] != 2 or values[2] != 1:
        return None
    samples = values[1]
    if type(samples) is not float and type(samples) is not int:
        return None
    if samples != int(samples) or not 2 <= samples <= MAX_SAMPLES or len(values) != 3 + 2 * int(samples):
        return None
    n = int(samples)
    first = [float(x) for x in values[3:3+n]]
    second = [float(x) for x in values[3+n:]]
    mean0, mean1 = sum(first)/n, sum(second)/n
    a = sum((x-mean0)**2 for x in first) / n
    d = sum((y-mean1)**2 for y in second) / n
    b = sum((x-mean0)*(y-mean1) for x, y in zip(first, second)) / n
    if b <= 0 or abs(a-d) + abs(b) == 0:
        return None
    theta = 0.5 * math.atan2(2*b, a-d)
    vx, vy = math.cos(theta), math.sin(theta)
    # Pinned PCA projects the original feature matrix (not the centered one).
    return [vx*x + vy*y for x, y in zip(first, second)]
