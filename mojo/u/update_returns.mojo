from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime BAD:Float64=-1.0e300
@export("update_returns")
fn update_returns(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<3 or n>61:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    if v[0]<2.0 or v[0]>60.0 or v[0]!=Float64(Int(v[0])):return -1
    let count=Int(v[0])
    if n!=c_size_t(count+1):return -1
    var total=Float64(0)
    for i in range(count):
        let x=v[i+1]
        if x < -0.25 or x > 0.25:return -1
        total+=x
    let mean=total/Float64(count);var sq=Float64(0)
    for i in range(count):let d=v[i+1]-mean;sq+=d*d
    let sd=sqrt(sq/Float64(count-1))
    if not isfinite(mean) or not isfinite(sd) or sd==0.0:return -1
    let varval=100000.0*(1.6448536269514722*sd-mean)
    if not isfinite(varval):return -1
    let result=count+3
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(result):return -2
    for i in range(count):o[i]=v[i+1]
    o[count]=mean;o[count+1]=sd;o[count+2]=varval
    return Int64(result)
