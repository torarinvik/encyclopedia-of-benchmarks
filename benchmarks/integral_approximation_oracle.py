"""Reference for the bounded C++ Riemann-sum benchmark."""
from __future__ import annotations
import math

INVALID_RESULT = -1.0e300
MAX_INPUT_LENGTH = 4

def expected_result(values: list[int]) -> float:
    if (not isinstance(values,list) or len(values)!=4
            or any(type(x) is not int or not -(2**63)<=x<2**63 for x in values)):
        return INVALID_RESULT
    selector,lower,upper,delta=values
    if selector not in (0,1) or not 0<=lower<upper<=32 or not 1<=delta<=8:
        return INVALID_RESULT
    lo=lower/8.0;hi=upper/8.0;step=delta/8.0
    count=int((hi-lo)/step)
    if count>32:return INVALID_RESULT
    def f(x:float)->float:
        return x*x if selector==0 else x*x*x-x*x+378.0
    total=0.0
    for i in range(count):
        begin=lo+i*step
        end=lo+(i+1)*step
        total+=step*(f(begin)+f(end))/2.0
    return total if math.isfinite(total) else INVALID_RESULT
