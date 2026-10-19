from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("modular_arithmetic")
fn modular_arithmetic(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1
    let op=v[0];let m=v[1];let a=v[2];let b=v[3]
    if op<0 or op>2 or m<1 or m>1000000 or a<0 or a>=m or b<0 or b>=m:return -1
    if op==0:return (a+b)%m
    if op==1:return (a-b+m)%m
    return (a*b)%m
