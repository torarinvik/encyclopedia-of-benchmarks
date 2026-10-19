from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import floor,isfinite
@export("rayleigh_quotient")
fn rayleigh_quotient(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>273:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    let dv=v[0]
    if dv<1 or dv>16 or floor(dv)!=dv:return -1
    let d=Int(dv);if n!=c_size_t(1+d*d+d):return -1
    let voff=1+d*d
    for i in range(d*d):if v[1+i]<-1000 or v[1+i]>1000:return -1
    for r in range(d):
        for c in range(r+1,d):if v[1+r*d+c]!=v[1+c*d+r]:return -1
    var denominator:Float64=0.0
    for i in range(d):
        if v[voff+i]<-100 or v[voff+i]>100:return -1
        denominator+=v[voff+i]*v[voff+i]
    if denominator<=0 or not isfinite(denominator):return -1
    var numerator:Float64=0.0
    for c in range(d):
        var dot:Float64=0.0
        for r in range(d):dot+=v[voff+r]*v[1+r*d+c]
        numerator+=dot*v[voff+c]
    let result=numerator/denominator
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    o[0]=result;return 1
