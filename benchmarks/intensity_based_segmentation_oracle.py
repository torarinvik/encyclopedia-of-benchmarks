"""Oracle for the pinned Python ordered intensity threshold loop."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=12
INVALID_RESULT=-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or not 2<=len(values)<=MAX_INPUT_LENGTH:return INVALID_RESULT
    if any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):return INVALID_RESULT
    k=values[0]
    if not 0<=k<=4 or len(values)-k-1<1 or len(values)-k-1>7:return INVALID_RESULT
    thresholds=values[1:k+1];pixels=values[k+1:]
    if any(not 0<=x<=255 for x in thresholds+pixels):return INVALID_RESULT
    out=0;place=1
    for pixel in pixels:
        label=0
        for i,t in enumerate(thresholds):
            if pixel>t:label=i+1
        out+=label*place;place*=5
    return out
