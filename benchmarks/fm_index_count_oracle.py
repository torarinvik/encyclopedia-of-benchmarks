"""Primary FM-index count oracle for the bounded DOI 82/83 profile."""

MAX_INPUT_LENGTH = 42
MAX_OUTPUT_BYTES = 8
MAX_TEXT = 32
MAX_PATTERN = 8


def _fm_count(text, pattern):
    # The unique smallest sentinel is appended as byte 0.
    s = list(text) + [0]
    suffixes = sorted(range(len(s)), key=lambda i: tuple(s[i:]))
    bwt = [s[(i - 1) % len(s)] for i in suffixes]
    freq = [0] * 5
    for c in bwt:
        freq[c] += 1
    cumulative = [0] * 5
    total = 0
    for c in range(5):
        cumulative[c] = total
        total += freq[c]
    left, right = 0, len(s)
    for c in reversed(pattern):
        rank_left = sum(x == c for x in bwt[:left])
        rank_right = sum(x == c for x in bwt[:right])
        left = cumulative[c] + rank_left
        right = cumulative[c] + rank_right
        if left == right:
            return 0
    return right - left


def evaluate(values):
    if values is None or len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_TEXT or len(values) < n + 3:
        return -1, b""
    m_at = n + 1
    m = values[m_at]
    if not 1 <= m <= MAX_PATTERN or len(values) != m_at + 1 + m:
        return -1, b""
    text = values[1:m_at]
    pattern = values[m_at + 1:]
    if any(x < 1 or x > 4 for x in text + pattern):
        return -1, b""
    count = _fm_count(text, pattern)
    return 8, int(count).to_bytes(8, "little", signed=True)
