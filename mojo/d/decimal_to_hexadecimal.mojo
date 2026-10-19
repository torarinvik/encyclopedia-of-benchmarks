from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
@export("decimal_to_hexadecimal")
fn decimal_to_hexadecimal(value:Int64,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if value<0:return -1
    var width=1;var n=value
    while n>=16:width+=1;n/=16
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(width):return -2
    var pos=width;n=value
    while pos>0:
        pos-=1;let d=n%16
        if d<10:out[pos]=UInt8(48+d)
        else:out[pos]=UInt8(97+d-10)
        n/=16
    return Int64(width)
