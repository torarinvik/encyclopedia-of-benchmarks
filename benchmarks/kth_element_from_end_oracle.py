"""Oracle for bounded one-based k-th from end lookup."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=65
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH:return INVALID_RESULT
    if any(type(x) is not int or not I64_MIN<=x<=I64_MAX for x in values):return INVALID_RESULT
    k,*items=values
    if len(items)>64 or k<=0 or k>len(items) or any(not 0<=x<=100000 for x in items):return INVALID_RESULT
    return items[len(items)-k]
