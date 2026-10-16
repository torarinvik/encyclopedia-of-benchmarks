"""Runtime oracle for the pinned recursive equal-sum partition algorithm."""

MAX_INPUT_LENGTH = 17
MAX_COUNT = 16
MAX_VALUE = 1000


def expected_result(values: list[int]) -> int:
    if (len(values) < 1 or len(values) > MAX_INPUT_LENGTH
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_COUNT
            or len(values) != values[0] + 1
            or any(type(value) is not int or not 0 <= value <= MAX_VALUE for value in values[1:])):
        return -1
    numbers = values[1:]
    total = sum(numbers)
    if total % 2:
        return 0
    half = total // 2

    def can_partition(index: int, target: int) -> bool:
        if target == half:
            return True
        if index >= len(numbers) or target > half:
            return False
        return can_partition(index + 1, target + numbers[index]) or can_partition(index + 1, target)

    return int(can_partition(0, 0))
