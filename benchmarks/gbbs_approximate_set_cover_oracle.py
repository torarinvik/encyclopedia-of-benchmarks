"""Primary oracle for a bounded deterministic GBBS approximate set-cover profile."""
import struct

MAX_SETS = 8
MAX_ELEMENTS = 8
MAX_INPUT_LENGTH = 1 + MAX_SETS
MAX_PARSEABLE_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def solve(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    ns = values[0]
    ne = ns
    if not 1 <= ns <= MAX_SETS or len(values) != 1 + ns:
        return None
    limit = (1 << ne) - 1
    masks = list(values[1:])
    if any(mask < 0 or mask & ~limit for mask in masks):
        return None
    for u, mask in enumerate(masks):
        if mask & (1 << u):
            return None
        for v in range(ns):
            if bool(mask & (1 << v)) != bool(masks[v] & (1 << u)):
                return None
    uncovered = limit
    chosen = 0
    buckets = [mask.bit_count() for mask in masks]
    round_no = 0
    while uncovered:
        top = max(buckets, default=0)
        if top == 0:
            break
        group = [i for i, old_bucket in enumerate(buckets) if old_bucket == top]
        degree = [0] * ns
        eligible = []
        for i in group:
            degree[i] = (masks[i] & uncovered).bit_count()
            buckets[i] = degree[i]
            if degree[i] >= top:
                eligible.append(i)
        # The source randomizes this priority each bucket round. This profile
        # uses a stable cyclic permutation to make that source phase reproducible.
        priority_order = sorted(eligible, key=lambda i: ((i - round_no) % ns, i))
        wins = [0] * ns
        for e in range(ne):
            bit = 1 << e
            if not (uncovered & bit):
                continue
            contenders = [s for s in priority_order if masks[s] & bit]
            if contenders:
                wins[contenders[0]] += 1
        round_cover = 0
        for s in eligible:
            # For degrees <= 8 and epsilon=.01, both pinned GBBS bucket
            # thresholds equal the integer degree. A set joins iff it wins
            # every currently uncovered element in its neighborhood.
            if wins[s] >= top:
                round_cover |= 1 << s
        if round_cover == 0:
            if eligible:
                return None
            round_no += 1
            continue
        chosen |= round_cover
        covered = 0
        for s in range(ns):
            if round_cover & (1 << s):
                covered |= masks[s]
        uncovered &= ~covered
        for s in range(ns):
            if round_cover & (1 << s):
                buckets[s] = 0
        round_no += 1
    return chosen, uncovered


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and
            (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_LENGTH)
            or not isinstance(values, (list, tuple))):
        return INVALID_RESULT, b""
    if input_is_null or (input_length is not None and input_length != len(values)):
        return INVALID_RESULT, b""
    solved = solve(values)
    if solved is None:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    return MAX_OUTPUT_BYTES, struct.pack("<qq", *solved)


def expected_result(values):
    return expected_output(values)[0]
