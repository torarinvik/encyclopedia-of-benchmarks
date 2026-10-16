from collections.abc import Sequence
MAX_INPUT_LENGTH=11
def _solve(a):
    if len(a)<=1:return list(a)
    pivot=a[0];best=[]
    i=1
    while i<len(a):
        if a[i]<pivot:
            tail=[x for x in a[i+1:] if x>=a[i]]
            cand=[a[i]]+_solve(tail)
            if len(cand)>len(best):
                best=cand
                i=len(best)
        i+=1
    tail=[x for x in a[1:] if x>=pivot]
    cand=[pivot]+_solve(tail)
    if len(cand)>len(best):best=cand
    return best
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)<2 or len(values)>MAX_INPUT_LENGTH:return -1
    if any(type(x)is not int or not -(1<<63)<=x<(1<<63) for x in values):return -1
    n=values[0]
    if not 1<=n<=10 or len(values)!=n+1 or any(not -10<=x<=10 for x in values[1:]):return -1
    seq=_solve(values[1:]);packed=len(seq)
    for x in seq:packed=packed*21+x+10
    return packed
