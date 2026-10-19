from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn lower_bound_rec(v:UnsafePointer[Int64,ImmutAnyOrigin],target:Int64,left:Int,right:Int)->Int:
    if right<=left:return left
    let middle=(left+right)/2
    if target==v[middle]:return middle
    if target<v[middle]:return lower_bound_rec(v,target,left,middle)
    return lower_bound_rec(v,target,middle+1,right)
@export("lower_bound")
fn lower_bound(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,target:Int64) abi("C")->Int64:
    if n>512 or target < -2147483648 or target>2147483647 or (n!=0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if v[i] < -2147483648 or v[i]>2147483647 or (i>0 and v[i-1]>v[i]):return -1
    return Int64(lower_bound_rec(v,target,0,Int(n)-1))
