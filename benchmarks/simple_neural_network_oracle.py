"""Oracle for bounded deterministic forward_propagation."""
import math
INVALID_RESULT=-1.0e300
def expected_result(values):
    if not isinstance(values,(list,tuple)) or len(values)!=3 or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):return INVALID_RESULT
    expected,weight,count=values
    if not 0<=expected<=100 or not 1<=weight<=199 or weight%2!=1 or not 1<=count<=65536:return INVALID_RESULT
    layer=0.0
    for _ in range(count):
        layer=1.0/(1.0+math.exp(-0.02*weight))
        error=expected/100.0-layer
        delta=error*layer*(1.0-layer)
        weight+=0.02*delta
    return layer*100.0
