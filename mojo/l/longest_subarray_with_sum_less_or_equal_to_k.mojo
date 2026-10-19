from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_subarray_with_sum_less_or_equal_to_k")
fn longest_subarray_with_sum_less_or_equal_to_k(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>259:return -1
    let target=v[0];let count=v[1]
    if target<0 or target>2147483647 or count<0 or count>256 or n!=c_size_t(count+2):return -1
    var total:Int64=0
    for i in range(Int(count)):
        let x=v[2+i]
        if x<0 or x>2147483647:return -1
        total+=x
    if total>2147483647:return -1
    var left=0;var best=0;var sum:Int64=0
    for right in range(Int(count)):
        sum+=v[right+2]
        while sum>target and left<=right:sum-=v[left+2];left+=1
        let cur=if left<=right:right-left+1 else:0
        best=max(best,cur)
    return Int64(best)
