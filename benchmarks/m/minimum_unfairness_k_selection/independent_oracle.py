"""Independent endpoint/count reference for minimum selected range width."""

MAX_N = 64
MAX_VALID_INPUT_LENGTH = MAX_N + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MIN_VALUE = -1_000_000_000
MAX_VALUE = 1_000_000_000
INVALID = -1


def evaluate(packed: list[int]) -> int:
    if len(packed) < 4 or len(packed) > MAX_N + 2:
        return INVALID
    n, k = packed[0], packed[1]
    if not 2 <= n <= MAX_N or not 2 <= k <= n or len(packed) != n + 2:
        return INVALID
    values = packed[2:]
    if any(value < MIN_VALUE or value > MAX_VALUE for value in values):
        return INVALID

    endpoints: list[int] = []
    for value in values:
        if value not in endpoints:
            endpoints.append(value)
    best = 2_000_000_001
    for low in endpoints:
        for high in endpoints:
            if high < low:
                continue
            contained = 0
            for value in values:
                if low <= value <= high:
                    contained += 1
            if contained >= k and high - low < best:
                best = high - low
    return best
