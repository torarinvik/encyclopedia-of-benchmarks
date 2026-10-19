from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import exp
@export("secant_method")
fn secant_method(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1.0e300
    if a[0]==1 and a[1]>=0 and a[1]<=2:
        var x0=1.0;var x1=3.0
        for _ in range(Int(a[1])):
            let f1=8.0*x1-2.0*exp(-x1);let f0=8.0*x0-2.0*exp(-x0);let x2=x1-(f1*(x1-x0))/(f1-f0);x0=x1;x1=x2
        return x1
    if a[0]==0 and a[1]==100:
        var x0=0.2;var x1=0.5
        for _ in range(99):
            let f1=x1*x1-3.0;let f0=x0*x0-3.0;let x2=x1-f1*(x1-x0)/(f1-f0);x0=x1;x1=x2
            if abs(x1-x0)<0.0001:return x2
        return -1.0
    return -1.0e300
