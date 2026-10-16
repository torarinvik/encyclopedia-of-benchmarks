from collections.abc import Sequence
MAX_INPUT_LENGTH = 6
RADIX = 201
def expected_result(values: Sequence[int]) -> int:
    if not isinstance(values, (list, tuple)) or len(values) != 6:
        return -1
    if any(type(x) is not int or not -10 <= x <= 10 for x in values):
        return -1
    a00,a01,a10,a11,b00,b01=values
    out=(a00*b00,a00*b01,a01*b00,a01*b01,a10*b00,a10*b01,a11*b00,a11*b01)
    packed=0
    for x in out: packed=packed*RADIX+(x+100)
    return packed
