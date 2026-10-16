"""Reference decoder for the pinned two-state, three-symbol HMM example."""
from __future__ import annotations

import struct

MAX_OBSERVATIONS = 64
START = (0.6, 0.4)
TRANSITION = ((0.7, 0.3), (0.4, 0.6))
EMISSION = ((0.5, 0.4, 0.1), (0.1, 0.3, 0.6))


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_OBSERVATIONS
            or any(type(x) is not int or x not in (0, 1, 2) for x in values)):
        return -1, b""
    scores = [START[s] * EMISSION[s][values[0]] for s in range(2)]
    back = []
    for obs in values[1:]:
        next_scores = []
        pointers = []
        for state in range(2):
            candidates = [scores[prior] * TRANSITION[prior][state] * EMISSION[state][obs]
                          for prior in range(2)]
            prior = 0 if candidates[0] >= candidates[1] else 1
            next_scores.append(candidates[prior])
            pointers.append(prior)
        back.append(pointers)
        scores = next_scores
    state = 0 if scores[0] >= scores[1] else 1
    path = [0] * len(values)
    path[-1] = state
    for t in range(len(values) - 1, 0, -1):
        state = back[t - 1][state]
        path[t - 1] = state
    output = b"".join(struct.pack("<q", x) for x in path)
    return len(output), output
