from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn upper_search(v:UnsafePointer[Int64,ImmutAnyOrigin],target:Int64,left:Int64,right:Int64)->Int64:
    if right<=left:return left
    let middle=(left+right)/2
    if target<v[1+Int(middle)]:return upper_search(v,target,left,middle)
    return upper_search(v,target,middle+1,right)
@export("upper_bound")
fn upper_bound(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>513:return -1
    let target=v[0]
    if target < -2147483648 or target > 2147483647:return -1
    for i in range(1,Int(n)):
        if v[i] < -2147483648 or v[i] > 2147483647:return -1
        if i>1 and v[i-1]>v[i]:return -1
    return upper_search(v,target,0,Int64(n)-2)
