"""Independent class-W oracle for the bounded NAS IS workload."""

from bisect import bisect_left
from functools import lru_cache

TOTAL_KEYS = 1 << 20
MAX_KEY = 1 << 16
MAX_ITERATIONS = 10
SEED = 314159265
MULTIPLIER = 1220703125
STATE_MASK = (1 << 46) - 1
TEST_INDICES = (357773, 934767, 875723, 898999, 404505)
BASELINE_RANKS = (1249, 11698, 1039987, 1043896, 1048018)
MAX_PASSES = 10
MAX_OUTPUT_BYTES = 353
INVALID_RESULT = -1
OUTPUT_ERROR = -2


@lru_cache(maxsize=1)
def _initial_keys() -> tuple[int, ...]:
    """Generate keys using integer 46-bit states, independently of randlc."""
    state = SEED
    keys = []
    for _ in range(TOTAL_KEYS):
        four_state_sum = 0
        for _ in range(4):
            state = (state * MULTIPLIER) & STATE_MASK
            four_state_sum += state
        # MAX_KEY/4 is 2^14; the source truncates (2^14 * sum(states)/2^46).
        keys.append(four_state_sum >> 32)
    return tuple(keys)


def _histogram_ranks(keys: list[int], iteration: int) -> tuple[int, ...]:
    """Count exact key frequencies, then read strict-less ranks via prefix sums."""
    keys[iteration] = iteration
    keys[iteration + MAX_ITERATIONS] = MAX_KEY - iteration
    counts = [0] * MAX_KEY
    for key in keys:
        counts[key] += 1
    for key in range(1, MAX_KEY):
        counts[key] += counts[key - 1]
    return tuple(0 if keys[index] == 0 else counts[keys[index] - 1]
                 for index in TEST_INDICES)


def _expected_rank(index: int, iteration: int) -> int:
    if index < 2:
        return BASELINE_RANKS[index] + iteration - 2
    return BASELINE_RANKS[index] - iteration


def expected_output(pass_count: int) -> tuple[int, bytes]:
    """Return CSV partial-rank rows and the final NPB verification count."""
    if type(pass_count) is not int or not 1 <= pass_count <= MAX_PASSES:
        return INVALID_RESULT, b""

    keys = list(_initial_keys())
    _histogram_ranks(keys, 1)  # Source's untimed warm-up rank(1).
    passed_verification = 0
    rows = []
    for iteration in range(1, pass_count + 1):
        ranks = _histogram_ranks(keys, iteration)
        passed_verification += sum(
            rank == _expected_rank(index, iteration)
            for index, rank in enumerate(ranks)
        )
        rows.append(",".join(str(rank) for rank in ranks))

    ordered = sorted(keys)
    if all(ordered[index - 1] <= ordered[index]
           for index in range(1, TOTAL_KEYS)):
        passed_verification += 1
    if passed_verification != 5 * pass_count + 1:
        passed_verification = 0

    output = ("\n".join((*rows, str(passed_verification))) + "\n").encode("ascii")
    return len(output), output
