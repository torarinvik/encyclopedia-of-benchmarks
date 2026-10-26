"""Pairwise character-set compatibility oracle for directed perfect phylogeny."""
MAX_INPUT_LENGTH = 146
MAX_OUTPUT_BYTES = 8


def evaluate(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, m = values[0], values[1]
    if not 1 <= n <= 12 or not 1 <= m <= 12 or len(values) != 2 + n * m:
        return -1, b""
    matrix = values[2:]
    if any(cell not in (0, 1) for cell in matrix):
        return -1, b""
    taxa_sets = []
    for col in range(m):
        taxa_sets.append({row for row in range(n) if matrix[row * m + col] == 1})
    possible = 1
    for a in range(m):
        for b in range(a + 1, m):
            left, right = taxa_sets[a], taxa_sets[b]
            if left and right and left.isdisjoint(right) is False and not (left <= right or right <= left):
                possible = 0
    raw = int(possible).to_bytes(8, "little", signed=True)
    return 8, raw
