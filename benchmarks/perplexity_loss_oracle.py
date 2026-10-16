"""Oracle for the bounded source-faithful perplexity-loss workload."""

from __future__ import annotations

import math

MIN_BATCH = 1
MAX_BATCH = 8
MIN_TIME = 1
MAX_TIME = 16
MIN_VOCAB = 2
MAX_VOCAB = 16
PROBABILITY_SCALE = 1_000_000
EPSILON = 1e-7
MAX_INPUT_LENGTH = 3 + MAX_BATCH * MAX_TIME * (MAX_VOCAB + 1)
INVALID_RESULT = -1e300
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def expected_result(values: list[int]) -> float:
    if (
        not isinstance(values, list)
        or len(values) < 3
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT

    batch, time, vocab = values[:3]
    if not MIN_BATCH <= batch <= MAX_BATCH:
        return INVALID_RESULT
    if not MIN_TIME <= time <= MAX_TIME:
        return INVALID_RESULT
    if not MIN_VOCAB <= vocab <= MAX_VOCAB:
        return INVALID_RESULT

    token_count = batch * time
    probability_count = token_count * vocab
    if len(values) != 3 + token_count + probability_count:
        return INVALID_RESULT

    labels = values[3 : 3 + token_count]
    probabilities = values[3 + token_count :]
    if any(not 0 <= label < vocab for label in labels):
        return INVALID_RESULT
    for row in range(token_count):
        start = row * vocab
        probabilities_row = probabilities[start : start + vocab]
        if any(not 0 <= probability <= PROBABILITY_SCALE for probability in probabilities_row):
            return INVALID_RESULT
        if sum(probabilities_row) != PROBABILITY_SCALE:
            return INVALID_RESULT

    batch_total = 0.0
    for sentence in range(batch):
        log_total = 0.0
        for step in range(time):
            row = sentence * time + step
            label = labels[row]
            probability = probabilities[row * vocab + label] / PROBABILITY_SCALE
            probability = min(max(probability, EPSILON), 1.0)
            log_total += math.log(probability)
        batch_total += math.exp(-(log_total / time))
    return batch_total / batch
