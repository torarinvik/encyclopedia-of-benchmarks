"""Reference for the bounded factor-list uniqueness contract."""


def expected_result(values: list[int]) -> int:
    if len(values) > 256 or any(value < -(1 << 31) or value >= (1 << 31) for value in values):
        return -1
    return int(len(values) == len(set(values)))
