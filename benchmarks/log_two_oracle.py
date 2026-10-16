"""Oracle for the bounded JavaScript signed-shift log2 loop."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=1
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)!=1 or type(values[0]) is not int or not I64_MIN<=values[0]<=I64_MAX:return INVALID_RESULT
    n=values[0]
    if not 0<=n<1<<31:return INVALID_RESULT
    result=0
    while n>>1:
        n>>=1;result+=1
    return result
