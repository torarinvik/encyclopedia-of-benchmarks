from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("secant")
fn secant(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=5:return -1.0e300
    if a[0]!=0 or a[1]<1000000 or a[1]>1500000 or a[2]<1600000 or a[2]>2000000 or a[1]>=a[2] or a[3]<1 or a[3]>100000 or a[4]<0 or a[4]>32:return -1.0e300
    var x0=Float64(a[1])/1e6;var x1=Float64(a[2])/1e6;let tol=Float64(a[3])/1e9;let maxu=Int(a[4])
    for u in range(maxu+1):
        let f1=x1*x1-3.0;if abs(f1)<=tol:return x1
        if u==maxu:break
        let f0=x0*x0-3.0;let den=f1-f0;if den==0:return -1.0e300
        let x2=x1-f1*(x1-x0)/den;x0=x1;x1=x2
    return -1.0e300
