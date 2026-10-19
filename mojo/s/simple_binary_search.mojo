from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn sbs(a:UnsafePointer[Int64,ImmutAnyOrigin],lo:Int,hi:Int,t:Int64)->Int64:
    if lo>=hi:return 0
    let mid=lo+(hi-lo)/2
    if a[mid]==t:return 1
    if t<a[mid]:return sbs(a,lo,mid,t)
    return sbs(a,mid+1,hi,t)
@export("simple_binary_search")
fn simple_binary_search(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,t:Int64) abi("C")->Int64:
    if n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]():return 0
    return sbs(a,0,Int(n),t)
