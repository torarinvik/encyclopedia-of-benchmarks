from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64= -1.0e300
comptime PI=3.14159265358979323846264338327950288
@export("sphere")
fn sphere(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return BAD
    let mode=v[0];let r=v[1]
    if (mode!=0 and mode!=1) or r<0 or r>1000000:return BAD
    let x=Float64(r);let r2=x*x
    if mode==0:return (((r2*x)*PI)*4.0)/3.0
    return (r2*PI)*4.0
