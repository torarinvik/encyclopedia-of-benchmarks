"""Independent direct-search verifier for the bounded FM-index profile."""

MAX_INPUT_LENGTH = 42
MAX_OUTPUT_BYTES = 8


def evaluate(values):
    if values is None or len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n = values[0]
    if n < 1 or n > 32 or len(values) < n + 3:
        return -1, b""
    m_at = n + 1
    m = values[m_at]
    if m < 1 or m > 8 or len(values) != n + m + 2:
        return -1, b""
    text, pattern = values[1:m_at], values[m_at + 1:]
    if any(v < 1 or v > 4 for v in text + pattern):
        return -1, b""
    count = 0
    if len(pattern) <= len(text):
        for start in range(len(text) - len(pattern) + 1):
            if text[start:start + len(pattern)] == pattern:
                count += 1
    return 8, count.to_bytes(8, "little", signed=True)
