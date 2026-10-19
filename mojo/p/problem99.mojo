from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import log10
@export("problem99")
fn problem99(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1:return -1
    let count=input[0]
    if count<0 or count>1000 or length!=c_size_t(1+2*count):return -1
    var largest=Float64(0);var result=Int64(0)
    for i in range(Int(count)):
        let base=input[1+2*i];let exponent=input[2+2*i]
        if base<1 or base>1000000 or exponent<0 or exponent>1200000:return -1
        let value=Float64(exponent)*log10(Float64(base))
        if value>largest:largest=value;result=Int64(i+1)
    return result
