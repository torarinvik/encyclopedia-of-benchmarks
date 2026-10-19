from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("ipv4_conversion")
fn ipv4_conversion(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=4:return -9223372036854775807-1
    var address:Int64=0
    for i in range(4):
        let octet=input[i]
        if octet<0 or octet>255:return -9223372036854775807-1
        address=address*256+octet
    return address
