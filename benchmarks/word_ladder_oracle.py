"""Oracle for the bounded Java WordLadder shortest-length contract."""
MAX_WORD_LENGTH = 5
MAX_WORDS = 32

def expected_result(values):
    if not isinstance(values, (list, tuple)) or len(values) < 4 or any(type(v) is not int for v in values):
        return -1
    width, start, end, count = values[:4]
    if not 1 <= width <= MAX_WORD_LENGTH or not 0 <= count <= MAX_WORDS or len(values) != 4 + count:
        return -1
    limit = 26 ** width
    words = values[4:]
    if any(not 0 <= word < limit for word in (start, end, *words)):
        return -1
    dictionary = set(words)
    if end not in dictionary:
        return 0
    queue = [(start, 1)]
    visited = {start}
    factors = [26 ** i for i in range(width)]
    cursor = 0
    while cursor < len(queue):
        current, level = queue[cursor]
        cursor += 1
        for factor in factors:
            digit = (current // factor) % 26
            for replacement in range(26):
                if replacement == digit:
                    continue
                candidate = current + (replacement - digit) * factor
                if candidate == end:
                    return level + 1
                if candidate in dictionary and candidate not in visited:
                    visited.add(candidate)
                    queue.append((candidate, level + 1))
    return 0

def expected_output(values):
    result = expected_result(values)
    return (8, result.to_bytes(8, 'little', signed=True)) if result >= 0 else (-1, b'')
