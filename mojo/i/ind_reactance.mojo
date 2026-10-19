from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("ind_reactance")
fn ind_reactance(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1.0e300
    let l=input[0];let f=input[1];let x=input[2]
    if l<0 or l>1000 or f<0 or f>1000 or x<0 or x>1000:return -1.0e300
    let zeros=(1 if l==0 else 0)+(1 if f==0 else 0)+(1 if x==0 else 0)
    if zeros!=1:return -1.0e300
    let pi=3.14159265358979323846
    if l==0:return Float64(x)/(2.0*pi*Float64(f))
    if f==0:return Float64(x)/(2.0*pi*Float64(l))
    return 2.0*pi*Float64(f)*Float64(l)
