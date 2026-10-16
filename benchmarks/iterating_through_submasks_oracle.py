"""Oracle for the pinned positive-mask submask enumeration."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=1
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)!=1 or type(values[0]) is not int or not I64_MIN<=values[0]<=I64_MAX:return INVALID_RESULT
    mask=values[0]
    if not 1<=mask<=4095:return INVALID_RESULT
    count=0;submask=mask
    while submask:
        count+=1;submask=(submask-1)&mask
    return count
