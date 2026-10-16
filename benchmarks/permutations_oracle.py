"""Oracle for the bounded sorted-input permutation-list hash."""
from itertools import permutations
MAX_INPUT_LENGTH = 7
MAX_COUNT = 6
MIN_I32 = -(1 << 31)
MAX_I32 = (1 << 31) - 1
INVALID_RESULT = -1

def _mix_value(h: int, value: int) -> int:
    unsigned = value & 0xFFFFFFFF
    for shift in (0, 8, 16, 24):
        h = ((h ^ ((unsigned >> shift) & 255)) * 16777619) & 0xFFFFFFFF
    return h

def expected_result(values: list[int]) -> int:
    if (not isinstance(values,list) or not 2<=len(values)<=MAX_INPUT_LENGTH
            or any(type(x) is not int for x in values)):
        return INVALID_RESULT
    count=values[0]; items=values[1:]
    if not 1<=count<=MAX_COUNT or len(items)!=count or any(not MIN_I32<=x<=MAX_I32 for x in items):
        return INVALID_RESULT
    if any(items[i-1]>=items[i] for i in range(1,count)):
        return INVALID_RESULT
    h=2166136261
    for row in permutations(items):
        for value in row:
            h=_mix_value(h,value)
        h=((h^255)*16777619)&0xFFFFFFFF
    return h
