"""Oracle for the bounded Ispell bucket-chain lookup profile."""
MAX_TABLE = 8
MAX_ENTRIES = 8
MAX_WORD = 8
MAX_QUERY = 8
MAX_INPUT_LENGTH = 107
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1

def _hash(word, table_size):
    h = 0
    for b in word[:4]:
        h = ((h << 8) | (b - 32)) & 0xffffffff
    for b in word[4:]:
        h = (((h << 5) | (h >> 27)) & 0xffffffff) ^ (b - 32)
    return h % table_size

def expected_result(values):
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value <= (1 << 63) - 1
                   for value in values)):
        return INVALID_RESULT
    m, qn, en = values[:3]
    if not 1 <= m <= MAX_TABLE or not 1 <= qn <= MAX_QUERY or not 0 <= en <= MAX_ENTRIES:
        return INVALID_RESULT
    p = 3
    q = values[p:p+qn]; p += qn
    heads = values[p:p+m]; p += m
    nxt = values[p:p+en]; p += en
    lens = values[p:p+en]; p += en
    if len(q) != qn or len(heads) != m or len(nxt) != en or len(lens) != en:
        return INVALID_RESULT
    if any(not 97 <= b <= 122 for b in q): return INVALID_RESULT
    if any(x < -1 or x >= en for x in heads+nxt): return INVALID_RESULT
    if any(not 1 <= x <= MAX_WORD for x in lens): return INVALID_RESULT
    words = []
    for size in lens:
        w = values[p:p+size]
        if len(w) != size or any(not 97 <= b <= 122 for b in w): return INVALID_RESULT
        words.append(w); p += size
    if p != len(values): return INVALID_RESULT
    seen = set()
    for bucket, head in enumerate(heads):
        node = head
        while node != -1:
            if node in seen: return INVALID_RESULT
            seen.add(node)
            if _hash(words[node], m) != bucket: return INVALID_RESULT
            node = nxt[node]
    if len(seen) != en: return INVALID_RESULT
    bucket = _hash(q, m)
    node = heads[bucket]
    while node != -1:
        if words[node] == q: return node + 1
        node = nxt[node]
    return 0

oracle = expected_result
