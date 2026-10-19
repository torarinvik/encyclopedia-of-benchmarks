from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn rbs_rec(v:UnsafePointer[Int64,ImmutAnyOrigin],lo:Int,hi:Int,target:Int64)->Int64:
    if lo>=hi:return -1
    let mid=lo+(hi-lo)//2
    if v[mid]==target:return Int64(mid)
    if target<v[mid]:return rbs_rec(v,lo,mid,target)
    return rbs_rec(v,mid+1,hi,target)
@export("recursive_binary_search")
fn recursive_binary_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,target:Int64) abi("C")->Int64:
    return rbs_rec(v,0,Int(n),target)
