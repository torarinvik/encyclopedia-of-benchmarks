from collections.abc import Sequence
MAX_INPUT_LENGTH=19
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)<4 or len(values)>MAX_INPUT_LENGTH:return -1
    if any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):return -1
    n,mode,k=values[:3]
    if not 1<=n<=16 or len(values)!=n+3 or mode not in (1,2) or not 1<=k<=n:return -1
    if any(not -10000<=x<=10000 for x in values[3:]):return -1
    return sorted(values[3:])[k-1 if mode==1 else n-k]
