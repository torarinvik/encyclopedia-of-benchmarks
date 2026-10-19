from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("verlet")
fn verlet(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=4:return -1
    for i in range(4):
        if not isfinite(v[i]):return -1
    if v[0]<2 or v[0]>32 or v[0]!=Float64(Int(v[0])) or abs(v[1])>1 or abs(v[2])>1 or v[3]<0 or v[3]>4 or v[3]!=Float64(Int(v[3])):return -1
    let count=Int(v[0]);let code=Int(v[3]);var dt=0.00390625
    if code==1:dt=0.0078125
    elif code==2:dt=0.015625
    elif code==3:dt=0.03125
    elif code==4:dt=0.0625
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(2*count):return -2
    let d2=dt*dt;o[0]=v[1];o[1]=v[1]+v[2]*dt+0.5*(-v[1])*d2
    for i in range(1,count-1):o[i+1]=2.0*o[i]-o[i-1]+(-o[i])*d2
    for i in range(count):o[count+i]=Float64(i)*dt
    return Int64(2*count)
