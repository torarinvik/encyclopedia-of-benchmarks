"""Oracle for bounded longest non-decreasing subsequence length."""
from collections.abc import Sequence
MAX_COUNT=64
MAX_INPUT_LENGTH=MAX_COUNT+1
MIN_VALUE,MAX_VALUE=-1_000_000,1_000_000
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values: Sequence[int]) -> int:
    if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH or any(type(v)is not int or not I64_MIN<=v<=I64_MAX for v in values): return INVALID_RESULT
    n=values[0]
    if not 0<=n<=MAX_COUNT or len(values)!=n+1 or any(not MIN_VALUE<=v<=MAX_VALUE for v in values[1:]):return INVALID_RESULT
    dp=[1]*n
    for i in range(n):
        for j in range(i):
            if values[j+1]<=values[i+1] and dp[j]+1>dp[i]:dp[i]=dp[j]+1
    return max(dp,default=0)
