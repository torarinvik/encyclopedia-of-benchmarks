from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("octal_to_hexadecimal")
fn octal_to_hexadecimal(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>21:return -1
    var value:Int64=0
    for i in range(Int(n)):
        if v[i]<0 or v[i]>7:return -1
        value=value*8+v[i]
    var width=1;var rem=value
    while rem>=16:width+=1;rem/=16
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(width):return -2
    rem=value
    for p in range(width):
        let pos=width-1-p;let digit=rem%16
        o[pos]=UInt8(if digit<10:48+digit else:97+digit-10);rem/=16
    return Int64(width)
