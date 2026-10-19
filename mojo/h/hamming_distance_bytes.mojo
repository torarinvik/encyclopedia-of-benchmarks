from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("hamming_distance_bytes")
fn hamming_distance_bytes(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>2050:return -1
    let n=values[0]
    if n<0 or n>1024 or length!=c_size_t(1+2*n):return -1
    var count:Int64=0
    for i in range(Int(n)):
        let a=values[1+i];let b=values[1+Int(n)+i]
        if a<0 or a>255 or b<0 or b>255:return -1
        if a!=b:count+=1
    return count
