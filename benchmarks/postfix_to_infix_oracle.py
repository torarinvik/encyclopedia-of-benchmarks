"""Oracle for bounded Java-style postfix-to-infix conversion."""

MAX_INPUT_LENGTH = 65
MAX_TOKENS = 64
MAX_OUTPUT_BYTES = 125
INVALID_RESULT = -1
OPERATORS = b"+-*/^"


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int for x in values)):
        return INVALID_RESULT, b""
    count, tokens = values[0], values[1:]
    if type(count) is not int or not 0 <= count <= MAX_TOKENS or len(tokens) != count:
        return INVALID_RESULT, b""
    if any(not 0 <= x <= 127 for x in tokens):
        return INVALID_RESULT, b""
    if count == 0:
        return 0, b""
    if count == 1:
        if tokens[0] in range(ord("A"), ord("Z") + 1) or tokens[0] in range(ord("a"), ord("z") + 1):
            return 1, bytes(tokens)
        return INVALID_RESULT, b""
    stack = []
    for token in tokens:
        if token in OPERATORS:
            if len(stack) < 2:
                return INVALID_RESULT, b""
            right = stack.pop()
            left = stack.pop()
            stack.append(b"(" + left + bytes((token,)) + right + b")")
        else:
            if not (ord("A") <= token <= ord("Z") or ord("a") <= token <= ord("z")):
                return INVALID_RESULT, b""
            stack.append(bytes((token,)))
    if len(stack) != 1 or len(stack[0]) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    return len(stack[0]), stack[0]
