"""Oracle for longest palindromic substring length under Go source filtering."""
from collections.abc import Sequence
MAX_COUNT=64
MAX_INPUT_LENGTH=MAX_COUNT+1
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH or any(type(x)is not int or not I64_MIN<=x<=I64_MAX for x in values):return INVALID_RESULT
    n=values[0]
    if not 0<=n<=MAX_COUNT or len(values)!=n+1:return INVALID_RESULT
    a=values[1:]
    if any(x<32 or x>126 or x==35 for x in a):return INVALID_RESULT
    s=[x for x in a if x!=32]
    return max((j-i for i in range(len(s)) for j in range(i+1,len(s)+1) if s[i:j]==s[i:j][::-1]),default=0)
