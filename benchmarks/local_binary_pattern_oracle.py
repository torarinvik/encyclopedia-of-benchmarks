from collections.abc import Sequence
MAX_INPUT_LENGTH=9
INVALID_RESULT=-1
ORDER=(2,5,1,8,7,6,3,0)
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)!=9 or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):return -1
    if any(x<0 or x>255 for x in values):return -1
    center=values[4]
    return sum((1<<i) for i,j in enumerate(ORDER) if values[j]>=center)
