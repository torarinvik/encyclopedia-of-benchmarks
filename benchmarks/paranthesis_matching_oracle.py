"""Oracle for the bounded ASCII delimiter matcher."""
MAX_INPUT_LENGTH = 100
OPEN_TO_CLOSE = {40: 41, 123: 125, 91: 93, 60: 62}
CLOSE_TO_OPEN = {v: k for k, v in OPEN_TO_CLOSE.items()}
def expected_result(values):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return -1
    if any(type(x) is not int or not 33 <= x <= 126 for x in values):
        return -1
    count = values[0]
    if not 1 <= count <= 99 or len(values) != count + 1:
        return -1
    stack=[]
    for ch in values[1:]:
        if ch in OPEN_TO_CLOSE: stack.append(ch)
        elif ch in CLOSE_TO_OPEN:
            if not stack or stack.pop() != CLOSE_TO_OPEN[ch]: return 0
        else: return 0
    return int(not stack)
