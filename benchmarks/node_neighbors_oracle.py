"""Runtime oracle for ordered unique neighbors in an undirected edge list."""

MAX_INPUT_LENGTH = 130
MAX_OUTPUT_BYTES = 192


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    count, node = values[:2]
    if not 0 <= count <= 64 or not 0 <= node <= 63 or len(values) != 2 + 2 * count:
        return -1, b""
    neighbors = []
    seen = set()
    for i in range(count):
        a, b = values[2 + 2*i:4 + 2*i]
        if not 0 <= a <= 63 or not 0 <= b <= 63:
            return -1, b""
        candidate = b if a == node else a if b == node else None
        if candidate is not None and candidate not in seen:
            seen.add(candidate)
            neighbors.append(candidate)
    output = ",".join(map(str, neighbors)).encode("ascii")
    return len(output), output
