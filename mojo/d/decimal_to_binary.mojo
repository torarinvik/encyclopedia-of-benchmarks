from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("decimal_to_binary")
fn decimal_to_binary(value:Int64,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if value<0:return -1
    var width=1;var n=value
    while n>1:width+=1;n/=2
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(width):return -2
    var pos=width
    while pos>0:pos-=1;output[pos]=UInt8(48+n%2);n/=2
    return Int64(width)
