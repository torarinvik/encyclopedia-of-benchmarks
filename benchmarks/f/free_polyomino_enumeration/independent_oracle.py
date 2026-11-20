"""Fixed-shape restricted-growth reference, then D4 canonicalization."""

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_RESULT = 369
FREE_COUNTS = (1, 1, 2, 5, 12, 35, 108, 369)
_NEIGHBORS = ((0, 1), (1, 0), (0, -1), (-1, 0))


def _canonical_free(cells):
    variants = []
    for swap in (False, True):
        for sx in (1, -1):
            for sy in (1, -1):
                points = []
                for x, y in cells:
                    a, b = (y, x) if swap else (x, y)
                    points.append((sx * a, sy * b))
                low_x = min(x for x, _ in points)
                low_y = min(y for _, y in points)
                variants.append(tuple(sorted((x - low_x, y - low_y) for x, y in points)))
    return min(variants)


def _is_canonical_half_plane(point):
    x, y = point
    return y > 0 or (y == 0 and x >= 0)


def _count_restricted_fixed_growth(n):
    cells = set()
    free_shapes = set()

    def visit(candidates, blocked):
        # A local stack is inherited by children after the selected point is
        # removed, matching the older-sibling exclusion in restricted growth.
        untried = candidates[:]
        unavailable = blocked.copy()
        while untried:
            point = untried.pop()
            if point in unavailable or point in cells:
                continue
            cells.add(point)
            child_blocked = unavailable | {point}
            if len(cells) == n:
                free_shapes.add(_canonical_free(cells))
            else:
                child_candidates = untried[:]
                new_points = []
                for x, y in (point,):
                    for dx, dy in _NEIGHBORS:
                        neighbor = (x + dx, y + dy)
                        if (not _is_canonical_half_plane(neighbor)
                                or neighbor in cells or neighbor in child_blocked
                                or neighbor in child_candidates or neighbor in new_points):
                            continue
                        new_points.append(neighbor)
                visit(child_candidates + new_points, child_blocked)
            cells.remove(point)
            unavailable.add(point)

    visit([(0, 0)], set())
    return len(free_shapes)


def expected_result(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if len(values) != MAX_VALID_INPUT_LENGTH or not 1 <= values[0] <= MAX_N:
        return -1
    return _count_restricted_fixed_growth(values[0])
