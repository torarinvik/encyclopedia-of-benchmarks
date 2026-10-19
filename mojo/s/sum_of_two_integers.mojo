from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn bitwise_add_i64(a:Int64,b:Int64)->Int64:
    var left=bitcast[UInt64](a);var right=bitcast[UInt64](b)
    while right!=0:
        let partial=left^right;right=(left&right)<<1;left=partial
    return bitcast[Int64](left)
@export("sum_of_two_integers")
fn sum_of_two_integers(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    if v[0]< -2147483648 or v[0]>2147483647 or v[1]< -2147483648 or v[1]>2147483647:return -1
    return bitwise_add_i64(v[0],v[1])
