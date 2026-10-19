from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn jp_rec(n:Int64,k:Int64)->Int64:
    if n==1:return 0
    return (jp_rec(n-1,k)+k%n)%n
@export("josephus_problem_recursive")
fn josephus_problem_recursive(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    if v[0]<1 or v[0]>256 or v[1]<1:return -1
    return jp_rec(v[0],v[1])+1
