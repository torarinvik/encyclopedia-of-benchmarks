"""Oracle for the pinned reward-ranked deadline filter."""
from collections.abc import Sequence
MAX_JOBS=64
MAX_INPUT_LENGTH=1+2*MAX_JOBS
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH or any(type(x)is not int or not I64_MIN<=x<=I64_MAX for x in values):return INVALID_RESULT
    n=values[0]
    if not 0<=n<=MAX_JOBS or len(values)!=1+2*n:return INVALID_RESULT
    jobs=[(values[1+2*i],values[2+2*i]) for i in range(n)]
    if any(not -1<=d<=64 or not -1_000_000<=r<=1_000_000 for d,r in jobs):return INVALID_RESULT
    order=sorted(range(n),key=lambda i:jobs[i][1],reverse=True)
    return sum(jobs[idx][0]>=rank for rank,idx in enumerate(order,start=1))
