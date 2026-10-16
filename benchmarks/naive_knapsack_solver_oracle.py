"""Independent oracle for the bounded input-order greedy knapsack trace."""

MAX_INPUT_LENGTH = 32

def expected_result(values: list[int]) -> int:
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1
    capacity, count = values[:2]
    if not 0 <= capacity <= 1_000_000 or not 0 <= count <= 30 or len(values) != count + 2:
        return -1
    weight = 0
    mask = 0
    for index, item_weight in enumerate(values[2:]):
        if not 0 <= item_weight <= 1_000_000:
            return -1
        if weight + item_weight <= capacity:
            weight += item_weight
            mask |= 1 << index
    return mask
