"""Runtime oracle for a bounded midpoint-rule integrator."""
import math
import struct

def expected_output(values:list[int])->tuple[int,bytes]:
    if not isinstance(values,list) or len(values)!=4 or any(type(x)is not int or not -(2**63)<=x<2**63 for x in values):return -1,b""
    function_id,steps,lower,upper=values
    if not 0<=function_id<=2 or not 1<=steps<=256 or not -1_000_000<=lower<=1_000_000 or not lower<=upper<=1_000_000:return -1,b""
    a=lower/1_000_000.0;b=upper/1_000_000.0
    h=(b-a)/steps;total=0.0
    for i in range(steps):
        x=a+i*h+h/2.0
        y=1.0 if function_id==0 else (x if function_id==1 else x*x)
        total+=y
    result=math.floor(h*total*1_000_000_000.0+0.5)
    return 8,struct.pack('<q',result)
