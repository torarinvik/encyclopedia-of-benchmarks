from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
@export("decimal_to_octal")
fn decimal_to_octal(value:Int64,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if value<0:return -1
    var width=1;var n=value
    while n>=8:width+=1;n/=8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(width):return -2
    var pos=width;n=value
    while pos>0:pos-=1;out[pos]=UInt8(48+n%8);n/=8
    return Int64(width)
