"""Independent bounded oracle for dictionary based English detection."""

MAX_DICTIONARY_WORDS = 8
MAX_WORD_LENGTH = 12
MAX_MESSAGE_LENGTH = 64
MAX_INPUT_LENGTH = 3 + MAX_DICTIONARY_WORDS * (MAX_WORD_LENGTH + 1) + MAX_MESSAGE_LENGTH


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or any(type(v) is not int or not 0 <= v <= 127 for v in values)):
        return -1
    if not values:
        return -1
    n = values[0]
    if not 0 <= n <= MAX_DICTIONARY_WORDS:
        return -1
    pos = 1
    words = []
    for _ in range(n):
        if pos >= len(values): return -1
        size = values[pos]; pos += 1
        if not 1 <= size <= MAX_WORD_LENGTH or pos + size > len(values): return -1
        word = bytes(values[pos:pos + size]); pos += size
        if not all(65 <= b <= 90 for b in word): return -1
        words.append(word.decode("ascii"))
    if words != sorted(set(words)) or pos >= len(values):
        return -1
    m = values[pos]; pos += 1
    if not 1 <= m <= MAX_MESSAGE_LENGTH or pos + m + 2 != len(values):
        return -1
    message = bytes(values[pos:pos + m]); pos += m
    word_pct, letter_pct = values[pos:pos + 2]
    if not 0 <= word_pct <= 100 or not 0 <= letter_pct <= 100:
        return -1
    retained = bytes(b for b in message if (65 <= b <= 90 or 97 <= b <= 122 or b in (9, 10, 32)))
    tokens = retained.upper().split()
    known = set(words)
    if not tokens:
        return -1
    return int(sum(w.decode("ascii") in known for w in tokens) * 100 >= word_pct * len(tokens)
               and len(retained) * 100 >= letter_pct * len(message))
