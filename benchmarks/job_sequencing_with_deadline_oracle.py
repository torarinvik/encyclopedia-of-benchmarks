"""Oracle for bounded greedy job sequencing with deadlines."""
from collections.abc import Sequence
MAX_JOBS=32
MAX_INPUT_LENGTH=1+2*MAX_JOBS
BASE=32_000_001
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH or any(type(x)is not int or not I64_MIN<=x<=I64_MAX for x in values):return INVALID_RESULT
    n=values[0]
    if not 1<=n<=MAX_JOBS or len(values)!=1+2*n:return INVALID_RESULT
    jobs=[(values[1+2*i],values[2+2*i]) for i in range(n)]
    if any(not 0<=d<=MAX_JOBS or not 0<=p<=1_000_000 for d,p in jobs):return INVALID_RESULT
    slots=[False]*(MAX_JOBS+1);count=profit=0
    for deadline,reward in sorted(jobs,key=lambda job:job[1],reverse=True):
        for slot in range(deadline,0,-1):
            if not slots[slot]:slots[slot]=True;count+=1;profit+=reward;break
    return count*BASE+profit
