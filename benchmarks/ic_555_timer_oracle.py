"""Independent oracle for the two bounded astable 555 calculations."""
from collections.abc import Sequence
INVALID_RESULT=-1.0e300
MAX_INPUT_LENGTH=4
MAX_COMPONENT=1_000_000
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values: Sequence[int]) -> float:
    if not isinstance(values,(list,tuple)) or len(values)!=4 or any(type(v)is not int or not I64_MIN<=v<=I64_MAX for v in values): return INVALID_RESULT
    mode,r1,r2,c=values
    if mode not in (0,1) or not (1<=r1<=MAX_COMPONENT and 1<=r2<=MAX_COMPONENT): return INVALID_RESULT
    if mode==0:
        if not 1<=c<=MAX_COMPONENT: return INVALID_RESULT
        return (1.44/((r1+2*r2)*c))*10**6
    if not 0<=c<=MAX_COMPONENT: return INVALID_RESULT
    return (r1+r2)/(r1+2*r2)*100
