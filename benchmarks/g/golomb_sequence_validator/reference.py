"""Queue-generated Golomb prefix reference for the bounded validator."""


def prefix(count):
    terms = [1, 2, 2]
    queue = [2]
    head, value = 0, 3
    while len(terms) < count:
        repetitions = queue[head]
        head += 1
        terms.extend([value] * repetitions)
        queue.extend([value] * repetitions)
        value += 1
    return terms[:count]


def expected(values):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= 1024:
        return -1
    if any(type(value) is not int for value in values):
        return -1
    if values[0] != len(values) or any(not -(2**31) <= value < 2**31 for value in values[1:]):
        return -1
    return int(list(values[1:]) == prefix(len(values) - 1))
