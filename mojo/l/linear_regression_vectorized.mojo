from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import isfinite
@export("linear_regression_vectorized")
fn linear_regression_vectorized(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<4 or n>45:return -1
    let sm=v[0];let fm=v[1];let itv=v[2]
    if not isfinite(sm) or not isfinite(fm) or not isfinite(itv) or sm<2 or sm>8 or fm<2 or fm>4 or itv<10 or itv>128:return -1
    let m=Int(sm);let f=Int(fm);let iterations=Int(itv)
    if Float64(m)!=sm or Float64(f)!=fm or Float64(iterations)!=itv or n!=c_size_t(4+m*f+m):return -1
    let alpha=v[3]
    if not isfinite(alpha) or alpha<0.0001 or alpha>0.01:return -1
    var x=InlineArray[Float64,32](fill=0.0);var y=InlineArray[Float64,8](fill=0.0)
    for i in range(m*f):
        let z=v[4+i]
        if not isfinite(z) or z < -1 or z>1:return -1
        x[i]=z
    for r in range(m):
        if x[r*f]!=1.0:return -1
    for r in range(m):
        let z=v[4+m*f+r]
        if not isfinite(z) or z < -1 or z>1:return -1
        y[r]=z
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(f):return -2
    var theta=InlineArray[Float64,4](fill=0.0);var errors=InlineArray[Float64,8](fill=0.0)
    for _ in range(iterations):
        for r in range(m):
            var pred=0.0
            for c in range(f):pred+=x[r*f+c]*theta[c]
            errors[r]=pred-y[r]
        var grad=InlineArray[Float64,4](fill=0.0)
        for c in range(f):
            for r in range(m):grad[c]+=x[r*f+c]*errors[r]
            grad[c]/=Float64(m)
        for c in range(f):theta[c]-=alpha*grad[c]
    for c in range(f):out[c]=theta[c]
    return Int64(f)
