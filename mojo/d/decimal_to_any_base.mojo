from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("decimal_to_any_base")
fn decimal_to_any_base(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    var value=input[0]; let base=input[1]
    if value<0 or base<2 or base>36:return -1
    var width=1;var n=value
    while n>=base:width+=1;n/=base
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(width):return -2
    var pos=width
    while pos>0:
        pos-=1;let d=value%base
        if d<10:output[pos]=UInt8(48+d)
        else:output[pos]=UInt8(65+d-10)
        value/=base
    return Int64(width)
