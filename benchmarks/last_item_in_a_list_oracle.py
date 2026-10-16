"""Oracle for bounded list last-element lookup."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=64
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)>MAX_INPUT_LENGTH:return INVALID_RESULT
    if any(type(x) is not int or not I64_MIN<=x<=I64_MAX or not 0<=x<=100000 for x in values):return INVALID_RESULT
    return values[-1] if values else INVALID_RESULT
