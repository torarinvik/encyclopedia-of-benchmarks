from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("linear_regression_cost")
fn linear_regression_cost(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1090:return -1.0e300
    let m=v[0];let f=v[1]
    if m<1 or m>64 or f<1 or f>16 or n!=c_size_t(2+m*f+f+m):return -1.0e300
    for i in range(2,Int(n)):
        if v[i]<-1000 or v[i]>1000:return -1.0e300
    let ws=2+Int(m*f);let ys=ws+Int(f);var total=0.0
    for r in range(Int(m)):
        var pred=0.0
        for c in range(Int(f)):pred+=Float64(v[2+r*Int(f)+c])*Float64(v[ws+c])
        let err=pred-Float64(v[ys+r]);total+=err*err
    return total/(2.0*Float64(m))
