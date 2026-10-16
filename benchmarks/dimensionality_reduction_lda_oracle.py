"""Oracle for a bounded two-class, two-feature LDA projection slice."""
import math

MAX_SAMPLES = 8
MAX_ABS_VALUE = 10_000


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 16
            or any(type(v) not in (int, float) or not math.isfinite(float(v)) for v in values)):
        return None
    if values[0] != 2 or values[2] != 2 or values[3] != 1:
        return None
    n_value = values[1]
    if type(n_value) not in (int, float) or n_value != int(n_value):
        return None
    n = int(n_value)
    if not 4 <= n <= MAX_SAMPLES or len(values) != 4 + 3*n:
        return None
    x = [float(v) for v in values[4:4+n]]
    y = [float(v) for v in values[4+n:4+2*n]]
    label_values = values[4+2*n:]
    if any(abs(v) > MAX_ABS_VALUE for v in x+y):
        return None
    if any(type(label) not in (int, float) or label not in (0, 1) for label in label_values):
        return None
    labels = [int(label) for label in label_values]
    indices = [[i for i, label in enumerate(labels) if label == c] for c in range(2)]
    if any(len(group) < 2 for group in indices):
        return None
    means = [[sum(axis[i] for i in group)/len(group) for axis in (x, y)] for group in indices]
    overall = [sum(axis)/n for axis in (x, y)]
    sw00 = sw01 = sw11 = 0.0
    for group in indices:
        for i in group:
            dx = x[i] - means[labels[i]][0]
            dy = y[i] - means[labels[i]][1]
            sw00 += dx*dx
            sw01 += dx*dy
            sw11 += dy*dy
    sw00 /= n
    sw01 /= n
    sw11 /= n
    determinant = sw00*sw11 - sw01*sw01
    if not determinant > 1e-12:
        return None
    delta0 = means[1][0] - means[0][0]
    delta1 = means[1][1] - means[0][1]
    w0 = (sw11*delta0 - sw01*delta1)/determinant
    w1 = (sw00*delta1 - sw01*delta0)/determinant
    norm = math.hypot(w0, w1)
    if not norm > 1e-12:
        return None
    w0 /= norm
    w1 /= norm
    if w0 < 0 or (abs(w0) <= 1e-14 and w1 < 0):
        w0, w1 = -w0, -w1
    # LDA's SVD-selected eigenvector projects the original, uncentered features.
    return [w0*x[i] + w1*y[i] for i in range(n)]
