"""Independent bounded oracle for the NIMPLY gate."""

def expected_result(values: list[int]) -> int:
    if len(values) != 2 or any(value not in (0, 1) for value in values):
        return -1
    return int(values[0] == 1 and values[1] == 0)
