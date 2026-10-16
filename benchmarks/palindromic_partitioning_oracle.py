"""Oracle for minimum-cut ASCII palindrome partitioning."""

MAX_TEXT_BYTES = 64
MAX_INPUT_LENGTH = 65


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1
    count = values[0]
    if not 1 <= count <= MAX_TEXT_BYTES or len(values) != count + 1:
        return -1
    text = values[1:]
    if any(not 0 <= value <= 127 for value in text):
        return -1
    palindrome = [[False] * count for _ in range(count)]
    for end in range(count):
        for start in range(end + 1):
            palindrome[start][end] = text[start] == text[end] and (end - start < 2 or palindrome[start + 1][end - 1])
    cuts = [0] * count
    for end in range(count):
        if palindrome[0][end]:
            cuts[end] = 0
        else:
            cuts[end] = min(cuts[start - 1] + 1 for start in range(1, end + 1) if palindrome[start][end])
    return cuts[-1]
