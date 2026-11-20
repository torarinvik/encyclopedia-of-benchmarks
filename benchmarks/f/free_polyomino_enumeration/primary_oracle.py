"""Canonical-growth reference for free polyomino counts through order eight."""

MAX_N = 8
MAX_SHAPES = 512
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_RESULT = 369
SYMBOL = "free_polyomino_enumeration"
FREE_COUNTS = (1, 1, 2, 5, 12, 35, 108, 369)

_NEIGHBORS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def _canonical(cells):
    best = None
    for mode in range(8):
        transformed = []
        for x, y in cells:
            a, b = (y, x) if mode >= 4 else (x, y)
            if mode & 1:
                a = -a
            if mode & 2:
                b = -b
            transformed.append((a, b))
        min_x = min(x for x, _ in transformed)
        min_y = min(y for _, y in transformed)
        candidate = tuple(sorted((x - min_x, y - min_y) for x, y in transformed))
        if best is None or candidate < best:
            best = candidate
    return best


def _count_by_canonical_growth(n):
    current = {((0, 0),)}
    for _size in range(1, n):
        following = set()
        for shape in current:
            occupied = set(shape)
            for x, y in shape:
                for dx, dy in _NEIGHBORS:
                    point = (x + dx, y + dy)
                    if point not in occupied:
                        following.add(_canonical((*shape, point)))
        if len(following) > MAX_SHAPES:
            return -1
        current = following
    return len(current)


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
    return _count_by_canonical_growth(values[0])
