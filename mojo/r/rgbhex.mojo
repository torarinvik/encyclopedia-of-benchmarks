from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("rgbhex")
fn rgbhex(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1
    let op=v[0];let x=v[1];let y=v[2];let z=v[3]
    if op==0:
        if x<0 or x>4294967295 or y!=0 or z!=0:return -1
        return x&16777215
    if op==1:
        if x<0 or x>255 or y<0 or y>255 or z<0 or z>255:return -1
        return (x<<16)|(y<<8)|z
    return -1
