from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("in_static_equilibrium")
fn in_static_equilibrium(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<5:return -1
    let n=input[0]
    if n<1 or n>100 or length!=c_size_t(1+4*n):return -1
    var moment:Int64=0
    for i in range(Int(n)):
        let fx=input[1+i];let fy=input[1+Int(n)+i];let lx=input[1+2*Int(n)+i];let ly=input[1+3*Int(n)+i]
        if fx< -1000 or fx>1000 or fy< -1000 or fy>1000 or lx< -1000 or lx>1000 or ly< -1000 or ly>1000:return -1
        moment+=lx*fy-ly*fx
    return 1 if moment==0 else 0
