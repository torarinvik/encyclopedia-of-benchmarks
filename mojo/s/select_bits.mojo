from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("select_bits")
fn select_bits(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>3:return -1
    let x=a[0];let f=1 if n<2 else a[1];let t=53 if n<3 else a[2]
    if x<0 or x>9007199254740991 or f<1 or f>53 or t<1 or t>53:return -1
    return (x%(1<<Int(t)))>>(f-1)
