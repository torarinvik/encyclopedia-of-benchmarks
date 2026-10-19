"""Oracle for the bounded Olden treeadd tree-construction benchmark."""

MAX_LEVEL = 12
MAX_NODES = (1 << MAX_LEVEL) - 1
ADDITION_PASSES = 100
INVALID_RESULT = -1


def expected_result(level: int) -> int:
    if type(level) is not int or not 0 <= level <= MAX_LEVEL:
        return INVALID_RESULT
    if level == 0:
        return 0

    # Every allocated node is one; the source returns the result of the last
    # of 100 identical TreeAdd traversals.
    node_count = 0
    nodes_at_level = 1
    for _ in range(level):
        node_count += nodes_at_level
        nodes_at_level *= 2
    return node_count
