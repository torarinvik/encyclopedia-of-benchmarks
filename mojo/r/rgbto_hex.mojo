from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn hexdigit(x:Int)->UInt8:return UInt8(if x<10:48+x else:87+x)
@export("rgbto_hex")
fn rgbto_hex(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    for i in range(3):if v[i]<0 or v[i]>255:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<7:return -2
    o[0]=35
    for i in range(3):o[1+2*i]=hexdigit(Int(v[i]>>4));o[2+2*i]=hexdigit(Int(v[i]&15))
    return 7
