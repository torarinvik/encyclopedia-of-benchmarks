"""Row-major frontier DP with canonical component labels for two colors."""

MAX_ROWS = 4
MAX_COLUMNS = 4
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_FRONTIER_STATES = 3 * 4 * (9 ** 4)
WORKSPACE_BYTES = 2 * MAX_FRONTIER_STATES * 8


def _parse(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return None
    rows, columns = values
    if not (2 <= rows <= MAX_ROWS and 2 <= columns <= MAX_COLUMNS):
        return None
    return rows, columns


def _color(code):
    if code == 0:
        return -1
    return 0 if code <= 4 else 1


def _canonical(codes):
    mapping = {}
    next_label = [0, 0]
    result = []
    for code in codes:
        if code == 0:
            result.append(0)
            continue
        color = _color(code)
        old_label = code if color == 0 else code - 4
        key = (color, old_label)
        if key not in mapping:
            next_label[color] += 1
            mapping[key] = next_label[color]
        label = mapping[key]
        result.append(label if color == 0 else 4 + label)
    return tuple(result)


def _advance(codes, closed, diagonal, color, row, column, width):
    if closed & (1 << color):
        return None

    above = codes[column]
    left = codes[column - 1] if column else 0
    if row and column:
        if (_color(above) == color and _color(left) == color
                and diagonal == color):
            return None

    updated = list(codes)
    old_above = above
    updated[column] = 0
    above_color = _color(above)
    left_color = _color(left)
    above_label = (above if color == 0 else above - 4) if above_color == color else 0
    left_label = (left if color == 0 else left - 4) if left_color == color else 0

    if above_label and left_label and above_label != left_label:
        keep, merge = above_label, left_label
        for slot, code in enumerate(updated):
            if color == 0 and code == merge:
                updated[slot] = keep
            elif color == 1 and code == 4 + merge:
                updated[slot] = 4 + keep
        left_label = keep

    chosen_label = above_label or left_label
    if not chosen_label:
        chosen_label = 1 + max(
            (code if color == 0 else code - 4)
            for code in updated if _color(code) == color
        ) if any(_color(code) == color for code in updated) else 1
    updated[column] = chosen_label if color == 0 else 4 + chosen_label

    next_closed = closed
    if old_above and above_color != color:
        old_color = above_color
        old_label = old_above if old_color == 0 else old_above - 4
        still_present = any(
            (_color(code) == old_color)
            and (code if old_color == 0 else code - 4) == old_label
            for code in updated
        )
        if not still_present:
            other_component = any(
                _color(code) == old_color
                and (code if old_color == 0 else code - 4) != old_label
                for code in updated
            )
            if other_component:
                return None
            next_closed |= 1 << old_color

    canonical = _canonical(updated)
    return canonical, next_closed, above_color


def _component_count(codes, color):
    labels = set()
    for code in codes:
        if _color(code) == color:
            labels.add(code if color == 0 else code - 4)
    return len(labels)


def _frontier_count(rows, columns):
    # State: (closed-color mask, prior diagonal color, canonical frontier codes).
    # Codes are 0 for an unused slot, 1..4 for black components, and 5..8
    # for white components. A uniquely completed color is closed and cannot
    # be assigned again; closing one of several same-color components is rejected.
    states = {(0, -1, (0, 0, 0, 0)): 1}
    for index in range(rows * columns):
        row, column = divmod(index, columns)
        following = {}
        for (closed, diagonal, codes), ways in states.items():
            for color in (0, 1):
                advanced = _advance(codes, closed, diagonal, color, row, column, columns)
                if advanced is None:
                    continue
                next_codes, next_closed, next_diagonal = advanced
                key = (next_closed, next_diagonal, next_codes)
                following[key] = following.get(key, 0) + ways
        states = following

    total = 0
    for (closed, _diagonal, codes), ways in states.items():
        black = _component_count(codes, 0)
        white = _component_count(codes, 1)
        if (((closed & 1) != 0 and black == 0)
                or ((closed & 1) == 0 and black == 1)) \
                and (((closed & 2) != 0 and white == 0)
                     or ((closed & 2) == 0 and white == 1)):
            total += ways
    return total


def expected_result(values):
    parsed = _parse(values)
    if parsed is None:
        return -1
    return _frontier_count(*parsed)
