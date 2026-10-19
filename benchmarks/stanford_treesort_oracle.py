"""Independent oracle for bounded Stanford Treesort output."""
from __future__ import annotations
MIN_RUNS = 1
MAX_RUNS = 100
ELEMENT_COUNT = 5000
MAX_OUTPUT_BYTES = 700
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _make_input() -> list[int]:
    seed = 74755
    result = []
    for _ in range(ELEMENT_COUNT):
        seed = (seed * 1309 + 13849) & 65535
        temp = seed
        result.append(temp - (temp // 100000) * 100000 - 50000)
    return result


def _tree_is_valid(values: list[int]) -> bool:
    # Use nested Python nodes and the upstream reversed ordering. Equality does
    # not descend: the source inserts only for strictly greater or smaller keys.
    root = [values[0], None, None]
    for value in values[1:]:
        node = root
        while True:
            if value > node[0]:
                slot = 1
            elif value < node[0]:
                slot = 2
            else:
                break
            if node[slot] is None:
                node[slot] = [value, None, None]
                break
            node = node[slot]

    def check(node: list) -> bool:
        left, right = node[1], node[2]
        if left is not None and (left[0] <= node[0] or not check(left)):
            return False
        if right is not None and (right[0] >= node[0] or not check(right)):
            return False
        return True

    return check(root)


def expected_output(runs: int) -> tuple[int, bytes]:
    """Return the source's output prefix for one through one hundred runs."""
    if type(runs) is not int or not MIN_RUNS <= runs <= MAX_RUNS:
        return INVALID_RESULT, b""
    values = _make_input()
    tree_valid = _tree_is_valid(values)
    rows = []
    for run in range(runs):
        rows.append(f"{values[run + 1]}\n")
        if not tree_valid:
            rows.append(" Error in Tree.\n")
    output = "".join(rows).encode("ascii")
    return len(output), output
