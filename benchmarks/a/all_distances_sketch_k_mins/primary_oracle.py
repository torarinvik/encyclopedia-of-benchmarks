"""Primary reference for all-distances k-mins MV/D records."""

MAX_N = 6
MAX_ASSIGNMENTS = 3
MAX_INPUT_WORDS = 26
MAX_OUTPUT_BYTES = 584


def _parse(values):
    if values is None or not 2 <= len(values) <= MAX_INPUT_WORDS:
        return None
    if any(type(value) is not int for value in values):
        return None
    n, assignment_count = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= assignment_count <= MAX_ASSIGNMENTS:
        return None
    if len(values) != 2 + n + assignment_count * n:
        return None
    distances = values[2:2 + n]
    if any(distance < 0 or distance > 1_000_000 for distance in distances):
        return None
    if any(distances[index - 1] >= distances[index] for index in range(1, n)):
        return None
    rank_rows = []
    start = 2 + n
    for row in range(assignment_count):
        ranks = values[start + row * n:start + (row + 1) * n]
        if sorted(ranks) != list(range(n)):
            return None
        rank_rows.append(ranks)
    return distances, rank_rows


def _encode(words):
    return b"".join(word.to_bytes(8, "little", signed=True) for word in words)


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    distances, rank_rows = parsed
    records = []
    for assignment, ranks in enumerate(rank_rows):
        best_rank = len(distances)
        for item, rank in enumerate(ranks):
            if rank < best_rank:
                records.append((assignment, item, rank, distances[item]))
                best_rank = rank
    words = [len(records)]
    for record in records:
        words.extend(record)
    output = _encode(words)
    if len(output) > MAX_OUTPUT_BYTES:
        return -1, b""
    return len(output), output
