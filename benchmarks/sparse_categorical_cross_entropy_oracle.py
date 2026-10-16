"""Bounded source-semantics oracle for sparse_categorical_cross_entropy."""
import math

INVALID_RESULT = -1.0e300
SCALE = 1_000_000.0
EPSILON = 1e-15

def sparse_categorical_cross_entropy(values):
    if values is None or len(values) < 1:
        return INVALID_RESULT
    a = list(values)
    if len(a) < 2:
        return INVALID_RESULT
    batch, classes = a[0], a[1]
    if not (1 <= batch <= 32 and 1 <= classes <= 32) or len(a) != 2 + batch + batch * classes:
        return INVALID_RESULT
    labels = a[2:2 + batch]
    probs = a[2 + batch:]
    if any(x < 0 or x >= classes for x in labels):
        return INVALID_RESULT
    for row in range(batch):
        items = probs[row * classes:(row + 1) * classes]
        if any(x < 0 or x > 1_000_000 for x in items) or sum(items) != 1_000_000:
            return INVALID_RESULT
    total = 0.0
    for row, label in enumerate(labels):
        probability = probs[row * classes + label] / SCALE
        total += -math.log(min(1.0, max(EPSILON, probability)))
    return total
