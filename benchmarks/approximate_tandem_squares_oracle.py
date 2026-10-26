"""Direct bounded oracle for approximate tandem squares (chapter 24)."""
MAX_INPUT_LENGTH = 34
MAX_OUTPUT_BYTES = 6160
MAX_OUTPUT_ELEMENTS = 770


def evaluate(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, budget = values[0], values[1]
    if not 2 <= n <= 32 or not 0 <= budget <= 8 or len(values) != n + 2:
        return -1, b""
    word = values[2:]
    if any(symbol < 0 or symbol > 3 for symbol in word):
        return -1, b""
    triples = []
    for start in range(n):
        for period in range(1, (n - start) // 2 + 1):
            mismatches = sum(word[start + i] != word[start + period + i]
                             for i in range(period))
            if mismatches <= budget:
                triples.extend((start, period, mismatches))
    result = [len(triples) // 3, *triples]
    raw = b"".join(int(x).to_bytes(8, "little", signed=True) for x in result)
    return len(raw), raw
