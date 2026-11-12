"""Independent row-transition profile oracle for domino tilings."""

MOD = 998_244_353
MAX_SIDE = 64
MAX_WIDTH = 8
MAX_AREA = 512


def _shape(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(x) is not int for x in values)):
        return None
    h, w = values
    if h < 1 or w < 1 or h > MAX_SIDE or w > MAX_SIDE or min(h, w) > MAX_WIDTH or h * w > MAX_AREA:
        return None
    return max(h, w), min(h, w)


def _row_transitions(width, incoming):
    """Return outgoing masks by explicitly laying horizontal pairs in free gaps."""
    full = (1 << width) - 1
    transitions = []
    for outgoing in range(1 << width):
        if incoming & outgoing:
            continue
        free = full & ~(incoming | outgoing)
        col = 0
        while col < width:
            if free & (1 << col):
                if col + 1 == width or not (free & (1 << (col + 1))):
                    break
                col += 2
            else:
                col += 1
        else:
            transitions.append(outgoing)
    return transitions


def expected_result(values):
    shape = _shape(values)
    if shape is None:
        return -1
    rows, width = shape
    transition_table = [_row_transitions(width, incoming) for incoming in range(1 << width)]
    counts = [0] * (1 << width)
    counts[0] = 1
    for row in range(rows):
        next_counts = [0] * (1 << width)
        for incoming, count in enumerate(counts):
            if count:
                for outgoing in transition_table[incoming]:
                    if row + 1 < rows or outgoing == 0:
                        next_counts[outgoing] = (next_counts[outgoing] + count) % MOD
        counts = next_counts
    return counts[0]
