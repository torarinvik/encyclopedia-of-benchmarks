"""Exact prefix-DP oracle for bounded concave-gap global alignment."""
import struct
from collections.abc import Sequence

MAX_INPUT=26

def expected_output(values:Sequence[int]|None,capacity:int|None=None,output_is_null:bool=False,input_is_null:bool=False,input_length:int|None=None)->tuple[int,bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:return -1,b""
    if capacity is not None and (type(capacity) is not int or capacity<0):return -1,b""
    if input_length is not None and (type(input_length) is not int or not 0<=input_length<=MAX_INPUT):return -1,b""
    if input_is_null and values not in (None,[],()):return -1,b""
    if not input_is_null and values is not None and input_length is not None and input_length!=len(values):return -1,b""
    if input_is_null or values is None or not isinstance(values,(list,tuple)):return -1,b""
    if len(values)<5 or len(values)>MAX_INPUT or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):return -1,b""
    n,m=values[:2];g=max(n,m)
    if not 1<=n<=8 or not 1<=m<=8 or len(values)!=2+n+m+g:return -1,b""
    x=list(values[2:2+n]);y=list(values[2+n:2+n+m]);w=list(values[2+n+m:])
    if any(not 0<=s<=3 for s in x+y) or any(not 0<=v<=100 for v in w):return -1,b""
    previous=None
    for i,cost in enumerate(w):
        slope=cost-(w[i-1] if i else 0)
        if previous is not None and slope>previous:return -1,b""
        if i and cost<w[i-1]:return -1,b""
        previous=slope
    inf=1<<60;dp=[[inf]*(m+1) for _ in range(n+1)];dp[0][0]=0
    for i in range(n+1):
        for j in range(m+1):
            if i and j:dp[i][j]=min(dp[i][j],dp[i-1][j-1]+(x[i-1]!=y[j-1]))
            for gap in range(1,i+1):dp[i][j]=min(dp[i][j],dp[i-gap][j]+w[gap-1])
            for gap in range(1,j+1):dp[i][j]=min(dp[i][j],dp[i][j-gap]+w[gap-1])
    payload=struct.pack("<q",dp[n][m])
    if output_is_null or capacity is not None and capacity<8:return -2,b""
    return 8,payload
