"""Independent oracle for bounded Needleman-Wunsch global alignment."""
INVALID_RESULT = -9223372036854775808
MAX_INPUT_LENGTH = 261

def expected_result(values):
    if not isinstance(values, (list, tuple)) or len(values) < 5 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    a, b, match, mismatch, gap = values[:5]
    if (type(a) is not int or type(b) is not int or not 0 <= a <= 128 or not 0 <= b <= 128
            or type(match) is not int or not 0 <= match <= 10
            or type(mismatch) is not int or not -10 <= mismatch <= 0
            or type(gap) is not int or not -10 <= gap <= 0 or len(values) != a+b+5):
        return INVALID_RESULT
    s1, s2 = values[5:5+a], values[5+a:]
    if any(type(c) is not int or not 65 <= c <= 90 for c in s1+s2):
        return INVALID_RESULT
    previous = [j*gap for j in range(b+1)]
    for i, left in enumerate(s1, 1):
        current = [i*gap] + [0]*b
        for j, right in enumerate(s2, 1):
            current[j] = max(previous[j-1] + (match if left == right else mismatch), previous[j] + gap, current[j-1] + gap)
        previous = current
    return previous[b]
