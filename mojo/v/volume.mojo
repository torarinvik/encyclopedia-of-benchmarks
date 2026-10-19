from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("volume")
fn volume(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1
    let op=v[0];let a=v[1];let b=v[2];let c=v[3]
    if a<0 or a>1000 or b<0 or b>1000 or c<0 or c>1000:return -1
    if op==0:
        if b!=0 or c!=0:return -1
        return a*a*a
    let p=a*b*c
    if op==1:return p
    if op==2:
        if p%2!=0:return -1
        return p/2
    if op==3:
        if p%3!=0:return -1
        return p/3
    return -1
