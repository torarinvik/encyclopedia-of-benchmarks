"""Independent oracle for Jenkins One-at-a-Time over bounded ASCII bytes."""
from collections.abc import Sequence
MAX_BYTES=64
MAX_INPUT_LENGTH=MAX_BYTES+1
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values: Sequence[int]) -> int:
    if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH or any(type(v)is not int or not I64_MIN<=v<=I64_MAX for v in values): return INVALID_RESULT
    n=values[0]
    if not 0<=n<=MAX_BYTES or len(values)!=n+1 or any(not 0<=b<=127 for b in values[1:]): return INVALID_RESULT
    h=0
    for b in values[1:]:
        h=(h+b)&0xffffffff; h=(h+(h<<10))&0xffffffff; h=(h^(h>>6))&0xffffffff
    h=(h+(h<<3))&0xffffffff; h=(h^(h>>11))&0xffffffff; h=(h+(h<<15))&0xffffffff
    return h
