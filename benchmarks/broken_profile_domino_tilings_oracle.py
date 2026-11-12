"""Primary frontier-mask oracle for open rectangular domino tilings."""

MODULUS = 998_244_353
MAX_SIDE = 64
MAX_PROFILE_WIDTH = 8
MAX_AREA = 512
MAX_INPUT_LENGTH = 2


def _decode(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    h, w = values
    if not (1 <= h <= MAX_SIDE and 1 <= w <= MAX_SIDE
            and min(h, w) <= MAX_PROFILE_WIDTH and h * w <= MAX_AREA):
        return None
    return max(h, w), min(h, w)


def _profile(height, width):
    states = 1 << width
    full = states - 1
    dp = [0] * states
    dp[0] = 1
    for row in range(height):
        nxt = [0] * states
        for incoming, ways in enumerate(dp):
            if ways == 0:
                continue
            for outgoing in range(states):
                if incoming & outgoing:
                    continue
                free = full ^ (incoming | outgoing)
                column = 0
                valid = True
                while column < width:
                    if (free >> column) & 1:
                        if column + 1 >= width or ((free >> (column + 1)) & 1) == 0:
                            valid = False
                            break
                        column += 2
                    else:
                        column += 1
                if valid and (row + 1 < height or outgoing == 0):
                    nxt[outgoing] = (nxt[outgoing] + ways) % MODULUS
        dp = nxt
    return dp[0]


def direct_small_result(values):
    """Direct first-empty-cell domino enumeration for boards of at most 30 cells."""
    decoded = _decode(values)
    if decoded is None:
        return -1
    h, w = values
    if h * w > 30:
        raise ValueError("direct enumeration is restricted to small boards")
    cells = h * w
    full = (1 << cells) - 1

    def visit(occupied):
        if occupied == full:
            return 1
        first = next(i for i in range(cells) if ((occupied >> i) & 1) == 0)
        row, col = divmod(first, w)
        total = 0
        if col + 1 < w and ((occupied >> (first + 1)) & 1) == 0:
            total += visit(occupied | (1 << first) | (1 << (first + 1)))
        if row + 1 < h and ((occupied >> (first + w)) & 1) == 0:
            total += visit(occupied | (1 << first) | (1 << (first + w)))
        return total

    return visit(0) % MODULUS


def expected_result(values):
    decoded = _decode(values)
    if decoded is None:
        return -1
    return _profile(*decoded)
