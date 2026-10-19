from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import pow
@export("geometric")
fn geometric(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1.0e300
    let op=v[0];let count=Int(n)-1
    if op==0:
        if count>16:return -1.0e300
        for i in range(1,Int(n)):if v[i]< -100 or v[i]>100:return -1.0e300
        if count==1:return 1.0
        if v[1]==0:return 0.0
        let ratio=Float64(v[2])/Float64(v[1])
        for i in range(count-1):
            if v[i+1]==0:return 0.0
            if Float64(v[i+2])/Float64(v[i+1])!=ratio:return 0.0
        return 1.0
    if op==1:
        if count>7:return -1.0e300
        var product:Int64=1
        for i in range(1,Int(n)):if v[i]<0 or v[i]>100:return -1.0e300;product*=v[i]
        return pow(Float64(product),1.0/Float64(count))
    return -1.0e300
