"""Independent bounded model of the Ispell ASCII word-hash helper."""
MAX_WORD_BYTES = 64
MAX_INPUT_LENGTH = MAX_WORD_BYTES + 1
INVALID_RESULT = -1

def expected_result(values):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    table_size = values[0]
    if not isinstance(table_size, int) or not 1 <= table_size <= 2_147_483_647:
        return INVALID_RESULT
    word = values[1:]
    if any(not isinstance(c, int) or c < 1 or c > 127 for c in word):
        return INVALID_RESULT
    def upper(c):
        return c - 32 if 97 <= c <= 122 else c
    h = 0
    prefix = word[:4]
    for c in prefix:
        h = ((h << 8) | upper(c)) & 0xffffffff
    for c in word[4:]:
        h = (((h << 5) | (h >> 27)) & 0xffffffff) ^ upper(c)
    return h % table_size
