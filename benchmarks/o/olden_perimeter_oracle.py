"""Bounded oracle for the TORONTO Olden quadtree perimeter workload."""

MAX_INPUT_LENGTH = 1
INVALID_RESULT = -1
ROOT_PERIMETER = 4096
MIN_LEVEL = 9
MAX_LEVEL = 11


def expected_result(values):
    if not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT
    level = values[0]
    if type(level) is not int or not MIN_LEVEL <= level <= MAX_LEVEL:
        return INVALID_RESULT

    # For these TORONTO depths every leaf is black: refinement reaches the
    # requested level before MakeTree's size < 512 white-cell cutoff.
    leaf_count_per_side = 1 << level
    leaf_edge = ROOT_PERIMETER // leaf_count_per_side
    exposed_edges = 4 * leaf_count_per_side
    return exposed_edges * leaf_edge
