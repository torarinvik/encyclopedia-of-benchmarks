from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("hexadecimal_to_binary")
fn hexadecimal_to_binary(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>16:return -1
    var value:UInt64=0
    for i in range(Int(n)):
        let d=a[i]
        if d<0 or d>15 or value>(0x7fffffffffffffff-UInt64(d))//16:return -1
        value=value*16+UInt64(d)
    var width=1;var x=value
    while x>1:x>>=1;width+=1
    if cap<c_size_t(width) or o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    for i in range(width):o[i]=UInt8(48+((value>>UInt(width-i-1))&1))
    return Int64(width)
