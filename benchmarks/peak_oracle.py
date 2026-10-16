"""Runtime oracle for the bounded divide-and-conquer peak finder."""

MAX_INPUT_LENGTH = 65
MAX_COUNT = 64
MAX_VALUE = 1_000_000


def expected_result(values: list[int]) -> int:
    if (len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or type(values[0]) is not int or not 3 <= values[0] <= MAX_COUNT
            or len(values) != values[0] + 1
            or any(type(x) is not int or not -MAX_VALUE <= x <= MAX_VALUE for x in values[1:])):
        return -1
    data = values[1:]
    peak_index = 1
    while peak_index < len(data) - 1 and data[peak_index] > data[peak_index - 1]:
        peak_index += 1
    if peak_index == 1 or peak_index >= len(data) - 1:
        return -1
    if any(data[i + 1] >= data[i] for i in range(peak_index, len(data) - 1)):
        return -1

    def find_peak(lo: int, hi: int) -> int:
        middle = (hi - lo) // 2
        left, center, right = data[lo + middle - 1], data[lo + middle], data[lo + middle + 1]
        if center > left and center > right:
            return center
        if left < right:
            start = middle - 1 if middle == 2 else middle
            return find_peak(lo + start, hi)
        end = middle + 1 if middle == 2 else middle
        return find_peak(lo, lo + end)
    return find_peak(0, len(data))
