"""Independent oracle for bounded maximum all-1 square side length."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=66
INVALID_RESULT=-2
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)<2 or len(values)>MAX_INPUT_LENGTH or any(type(x) is not int for x in values):return INVALID_RESULT
    r,c=values[:2]
    if not 1<=r<=8 or not 1<=c<=8 or len(values)!=2+r*c:return INVALID_RESULT
    cells=values[2:]
    if any(x not in (0,1) for x in cells):return INVALID_RESULT
    dp=[[0]*(c+1) for _ in range(r+1)];best=0
    for i in range(r-1,-1,-1):
        for j in range(c-1,-1,-1):
            if cells[i*c+j]:dp[i][j]=1+min(dp[i+1][j],dp[i][j+1],dp[i+1][j+1]);best=max(best,dp[i][j])
    return best
