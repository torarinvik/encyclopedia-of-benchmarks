from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn pu_rec(base:Int64,exp:Int64)->Int64:
    if exp==0:return 1
    return base*pu_rec(base,exp-1)
@export("power_using_recursion")
fn power_using_recursion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<-10 or v[0]>10 or v[1]<0 or v[1]>15:return -1
    return pu_rec(v[0],v[1])
