"""Oracle for the bounded recursive special-array product sum."""

MAX_INPUT_LENGTH = 129
MAX_TOKENS = 128
MAX_DEPTH = 16
MAX_LEAF = 1000
LIST_BEGIN = 2001
LIST_END = 2002
INVALID_RESULT = -1


def expected_result(values):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    count = values[0]
    if type(count) is not int or count < 0 or count > MAX_TOKENS or len(values) != count + 1:
        return INVALID_RESULT
    tokens = values[1:]
    if any(type(token) is not int for token in tokens):
        return INVALID_RESULT
    cursor = 0
    valid = True

    def parse(depth):
        nonlocal cursor, valid
        if depth > MAX_DEPTH:
            valid = False
            return 0
        total = 0
        while cursor < count:
            token = tokens[cursor]
            cursor += 1
            if token == LIST_END:
                if depth == 1:
                    valid = False
                return total * depth
            if token == LIST_BEGIN:
                total += parse(depth + 1)
            elif -MAX_LEAF <= token <= MAX_LEAF:
                total += token
            else:
                valid = False
                return 0
        if depth != 1:
            valid = False
        return total * depth

    result = parse(1)
    if not valid or cursor != count:
        return INVALID_RESULT
    return result
