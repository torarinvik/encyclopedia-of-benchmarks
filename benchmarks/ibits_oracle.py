from collections.abc import Sequence
MAX_INPUT_LENGTH=1
INVALID_RESULT=-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)!=1 or type(values[0]) is not int or not -(1<<63)<=values[0]<(1<<63):return -1
    n=values[0]
    if not 0<=n<(1<<53):return -1
    count=0
    while n>=1<<count:count+=1
    return count
