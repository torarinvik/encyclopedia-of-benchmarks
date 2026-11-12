"""Target-major direct verifier for the bounded SPLASH-2 FMM profile."""

from collections.abc import Sequence
from math import hypot, isfinite, log

MAX_PARTICLES = 48
MAX_INPUT_LENGTH = 1 + 3 * MAX_PARTICLES


def expected_output(values: Sequence[float] | None) -> tuple[int, tuple[float, ...]]:
    if (values is None or not isinstance(values, (list, tuple))
            or not 7 <= len(values) <= MAX_INPUT_LENGTH
            or (len(values) - 1) % 3 != 0
            or any(type(v) not in (int, float) or not isfinite(v) for v in values)):
        return -1, ()
    n = values[0]
    if n != int(n) or not 2 <= n <= MAX_PARTICLES or len(values) != 1 + 3 * int(n):
        return -1, ()
    points = []
    for index in range(int(n)):
        x, y, q = values[1 + 3 * index:4 + 3 * index]
        if x != int(x) or y != int(y) or not (0 <= x < 8 and 0 <= y < 8):
            return -1, ()
        if q != int(q) or not -3 <= q <= 3:
            return -1, ()
        points.append((int(x), int(y), int(q)))
    if len({(x, y) for x, y, _ in points}) != len(points):
        return -1, ()
    answer = [0.0 for _ in points]
    for source, (sx, sy, charge) in enumerate(points):
        for target, (tx, ty, _) in enumerate(points):
            if source == target:
                continue
            answer[target] += charge * log(hypot(sx - tx, sy - ty))
    return len(answer), tuple(answer)
