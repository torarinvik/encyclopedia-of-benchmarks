from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("elementary")
fn elementary(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64, ImmutAnyOrigin]() or length<2 or length>129: return -1
    let count=input[0]
    if count<1 or count>128 or length!=c_size_t(count+1) or input[1]!=0: return -1
    for i in range(Int(count)):
        let v=input[i+1]
        if v!=0 and v!=1: return -1
    if output==UnsafePointer[UInt8, MutAnyOrigin]() or capacity<c_size_t(count): return -2
    for i in range(Int(count)):
        let left=input[i] if i>0 else 0
        let center=input[i+1]
        let right=input[i+2] if i+1<Int(count) else 0
        output[i]=UInt8((30 >> Int(left*4+center*2+right))&1)
    return count
