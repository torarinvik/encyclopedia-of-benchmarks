"""Portable bounded 32-round Feistel cipher block core."""
MAX_INPUT_LENGTH = 3
MASK32 = (1 << 32) - 1
INVALID = -1

def _round_key(key: int, round_index: int) -> int:
    power = 1
    for _ in range(round_index + 2):
        power = (power * key) & MASK32
    return power ^ key

def _f(block: int, key: int) -> int:
    for _ in range(32):
        product = (((block ^ 0x55555555) * block) & MASK32)
        block = (product % key) ^ key
    return block

def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 3
            or any(type(value) is not int for value in values)):
        return INVALID
    mode, key, block = values
    if mode not in (0, 1) or not 1 <= key <= MASK32 or not -(1 << 63) <= block < (1 << 63):
        return INVALID
    if any(_round_key(key, round_index) == 0 for round_index in range(32)):
        return INVALID
    bits = block & ((1 << 64) - 1)
    left, right = (bits >> 32) & MASK32, bits & MASK32
    if mode == 0:
        for round_index in range(32):
            left, right = (right ^ _f(left, key=_round_key(key, round_index))), left
    else:
        for round_index in range(31, -1, -1):
            left, right = right, left ^ _f(right, _round_key(key, round_index))
    output = ((left << 32) | right) & ((1 << 64) - 1)
    return output if output < (1 << 63) else output - (1 << 64)
