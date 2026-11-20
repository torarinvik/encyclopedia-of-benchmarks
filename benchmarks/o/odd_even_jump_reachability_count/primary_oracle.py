"""Sorted-index monotone-stack and reverse two-state DP reference."""

MAX_N = 64
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
INVALID = -1


def _valid(values, input_is_null=False, input_length=None):
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return False
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return False
    if len(values) < 2 or len(values) > MAX_N + 1:
        return False
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or len(values) != n + 1:
        return False
    return all(type(value) is int and MIN_VALUE <= value <= MAX_VALUE
               for value in values[1:])


def expected(values, input_is_null=False, input_length=None):
    if not _valid(values, input_is_null, input_length):
        return INVALID
    data = list(values[1:])
    n = len(data)

    def successors(descending):
        order = sorted(range(n), key=lambda i: ((-data[i]) if descending else data[i], i))
        result = [-1] * n
        stack = []
        for index in order:
            while stack and stack[-1] < index:
                result[stack.pop()] = index
            stack.append(index)
        return result

    odd_next = successors(False)
    even_next = successors(True)
    odd = [False] * n
    even = [False] * n
    odd[-1] = even[-1] = True
    for index in range(n - 2, -1, -1):
        odd_target = odd_next[index]
        even_target = even_next[index]
        if odd_target >= 0:
            odd[index] = even[odd_target]
        if even_target >= 0:
            even[index] = odd[even_target]
    return sum(odd)
