"""Oracle for bounded truncation-toward-zero long division."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=2
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)!=2 or any(type(x) is not int or not I64_MIN<=x<=I64_MAX for x in values):return INVALID_RESULT
    a,b=values
    if not -1000000<=a<=1000000 or not -10000<=b<=10000:return INVALID_RESULT
    if b==0:return 0
    q=abs(a)//abs(b)
    return -q if (a<0) != (b<0) else q
