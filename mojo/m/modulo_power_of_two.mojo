from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("modulo_power_of_two")
fn modulo_power_of_two(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let x=v[0];let e=v[1]
    if x < -2147483648 or x>2147483647 or e<1 or e>31:return -1
    return x & ((Int64(1)<<e)-1)
