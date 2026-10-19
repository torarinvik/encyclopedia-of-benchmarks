from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("one_bit_difference")
fn one_bit_difference(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    if v[0]< -2147483648 or v[0]>2147483647 or v[1]< -2147483648 or v[1]>2147483647:return -1
    let diff=UInt32(Int32(v[0]))^UInt32(Int32(v[1]))
    return if diff!=0 and (diff&(diff-1))==0:1 else:0
