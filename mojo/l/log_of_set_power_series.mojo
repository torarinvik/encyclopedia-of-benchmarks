from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("log_of_set_power_series")
fn log_of_set_power_series(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                           output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>33: return -1
    if input[0]<0 or input[0]>5: return -1
    let size=1 << Int(input[0])
    if length!=c_size_t(1+size) or input[1]!=1: return -1
    for i in range(size):
        if input[1+i]<0 or input[1+i]>=998244353: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(8*size): return -2
    var result=InlineArray[Int64,32](fill=0)
    for mask in range(1,size):
        let pivot=mask & -mask
        var sub=(mask-1)&mask; var sum=Int64(0)
        while sub!=0:
            if (sub & pivot)!=0: sum=(sum+result[sub]*input[1+(mask^sub)])%998244353
            sub=(sub-1)&mask
        result[mask]=(input[1+mask]-sum+998244353)%998244353
    for i in range(size):
        for byte in range(8): output[8*i+byte]=UInt8((result[i] >> (8*byte)) & 255)
    return Int64(8*size)
