"""Runtime oracle for the bounded number-container change/find trace."""

MAX_INPUT_LENGTH = 97
MAX_OUTPUT_BYTES = 128


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not values
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    count = values[0]
    if not 0 <= count <= 32 or len(values) != 1 + 3 * count:
        return -1, b""
    at_index = {}
    answers = []
    for i in range(count):
        op, a, b = values[1 + 3*i:4 + 3*i]
        if op == 0:
            if not 0 <= a <= 63 or not -100 <= b <= 100:
                return -1, b""
            at_index[a] = b
        elif op == 1:
            if not -100 <= a <= 100 or b != 0:
                return -1, b""
            matches = [index for index, value in at_index.items() if value == a]
            answers.append(min(matches) if matches else -1)
        else:
            return -1, b""
    output = ",".join(map(str, answers)).encode("ascii")
    return len(output), output
