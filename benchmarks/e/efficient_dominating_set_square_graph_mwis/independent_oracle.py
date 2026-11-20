"""Direct subset reference checking exactly-once closed-neighborhood coverage."""

from .primary_oracle import _parse


def expected_result(values):
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, adjacency = parsed
    all_vertices = (1 << n) - 1
    closed_neighborhoods = [adjacency[v] | (1 << v) for v in range(n)]
    for selected in range(1 << n):
        covered = 0
        scan = selected
        valid = True
        while scan:
            bit = scan & -scan
            vertex = bit.bit_length() - 1
            neighborhood = closed_neighborhoods[vertex]
            if covered & neighborhood:
                valid = False
                break
            covered |= neighborhood
            scan ^= bit
        if valid and covered == all_vertices:
            return 1
    return 0
