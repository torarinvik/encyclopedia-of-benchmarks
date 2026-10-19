from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("format_phone_number")
fn format_phone_number(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=10: return -1
    for i in range(10):
        if input[i]<48 or input[i]>57: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<14: return -2
    output[0]=40
    for i in range(3): output[1+i]=UInt8(input[i])
    output[4]=41; output[5]=32
    for i in range(3): output[6+i]=UInt8(input[3+i])
    output[9]=45
    for i in range(4): output[10+i]=UInt8(input[6+i])
    return 14
