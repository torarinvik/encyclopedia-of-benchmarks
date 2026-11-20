"""Independent reference using a query-prefix scan for every distance."""

MAX_N = 6
MAX_ASSIGNMENTS = 3


def _valid(values):
    if values is None or not 2 <= len(values) <= 26:
        return False
    if any(type(value) is not int for value in values):
        return False
    n, assignments = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= assignments <= MAX_ASSIGNMENTS:
        return False
    if len(values) != 2 + n + n * assignments:
        return False
    distances = values[2:2 + n]
    if any(not 0 <= distance <= 1_000_000 for distance in distances):
        return False
    for index in range(1, n):
        if distances[index - 1] >= distances[index]:
            return False
    for row in range(assignments):
        ranks = values[2 + n + row * n:2 + n + (row + 1) * n]
        if set(ranks) != set(range(n)):
            return False
    return True


def evaluate(values):
    if not _valid(values):
        return -1, b""
    n, assignment_count = values[:2]
    distances = values[2:2 + n]
    records = []
    for assignment in range(assignment_count):
        row_start = 2 + n + assignment * n
        ranks = values[row_start:row_start + n]
        prior_winner = -1
        for query_index in range(n):
            winner = min(range(query_index + 1), key=ranks.__getitem__)
            if winner != prior_winner:
                records.append((assignment, winner, ranks[winner], distances[winner]))
                prior_winner = winner
    words = [len(records)]
    for assignment, item, rank, distance in records:
        words.extend((assignment, item, rank, distance))
    raw = b"".join(int(word).to_bytes(8, "little", signed=True) for word in words)
    return len(raw), raw
