from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("octal_to_binary")
fn octal_to_binary(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>21:return -1
    var value:Int64=0
    for i in range(Int(n)):
        if v[i]<0 or v[i]>7:return -1
        value=value*8+v[i]
    var width=1;var rem=value
    while rem>=2:width+=1;rem/=2
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(width):return -2
    rem=value
    for p in range(width):let pos=width-1-p;o[pos]=UInt8(48+rem%2);rem/=2
    return Int64(width)
