from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn subset_search(v:UnsafePointer[Int64,ImmutAnyOrigin],items:Int,index:Int,remaining:Int64,memo:UnsafePointer[Int64,MutAnyOrigin])->Int64:
    if remaining==0:return 1
    if index==items:return 0
    let state=index*801+Int(remaining+400)
    if memo[state]!= -2:return memo[state]
    var result=subset_search(v,items,index+1,remaining-v[index+1],memo)
    if result==0:result=subset_search(v,items,index+1,remaining,memo)
    memo[state]=result;return result
@export("subset_sum_dynamic")
fn subset_sum_dynamic(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>17:return -1
    if v[0]< -80 or v[0]>80:return -1
    for i in range(1,Int(n)):if v[i]< -20 or v[i]>20:return -1
    var memo=InlineArray[Int64,17*801](fill= -2)
    return subset_search(v,Int(n)-1,0,v[0],memo.unsafe_ptr())
