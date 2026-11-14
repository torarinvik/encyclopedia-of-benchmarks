"""Next-occurrence table reference for the bounded batched profile."""


def parse(values):
    if values is None or len(values) < 2:
        return None
    n, q = values[:2]
    if not 0 <= n <= 64 or not 0 <= q <= 32 or len(values) < 2 + n:
        return None
    text = values[2:2+n]
    if any(not 0 <= x <= 3 for x in text):
        return None
    position, total, queries = 2+n, 0, []
    for _ in range(q):
        if position >= len(values):
            return None
        size = values[position]
        position += 1
        if size < 0 or size > 256-total or size > len(values)-position:
            return None
        query = values[position:position+size]
        if any(not 0 <= x <= 3 for x in query):
            return None
        queries.append(query)
        position += size
        total += size
    return (text, queries) if position == len(values) else None


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    text, queries = parsed
    n = len(text)
    next_pos = [[n]*4 for _ in range(n+1)]
    for i in range(n-1, -1, -1):
        next_pos[i] = next_pos[i+1][:]
        next_pos[i][text[i]] = i
    result = 0
    for index, query in enumerate(queries, 1):
        cursor = 0
        for symbol in query:
            found = next_pos[cursor][symbol]
            if found == n:
                break
            cursor = found+1
        else:
            result += index
    return result
