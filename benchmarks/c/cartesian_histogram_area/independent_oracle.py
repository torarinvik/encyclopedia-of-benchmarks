"""Independent interval enumeration for the bounded histogram profile."""

INVALID = -(1 << 63)


def expected(heights, length=None, input_is_null=False):
    if input_is_null or heights is None:
        return 0 if length == 0 else INVALID
    if length is not None and length != len(heights):
        return INVALID
    if len(heights) > 64 or any(not 0 <= value <= 1000000 for value in heights):
        return INVALID
    answer = 0
    for start in range(len(heights)):
        minimum = 1000000
        for end in range(start, len(heights)):
            minimum = min(minimum, heights[end])
            answer = max(answer, minimum * (end-start+1))
    return answer
