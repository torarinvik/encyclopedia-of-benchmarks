from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minimum_size_subarray_sum")
fn minimum_size_subarray_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>258:return -1
    let target=v[0];let count=v[1]
    if target<1 or target>1000000 or count<0 or count>256 or Int(n)!=Int(count)+2:return -1
    for i in range(Int(count)):if v[i+2]<1 or v[i+2]>1000000:return -1
    var left=0;var sum:Int64=0;var best=Int(count)+1
    for right in range(Int(count)):
        sum+=v[right+2]
        while sum>=target:
            let width=right-left+1
            if width<best:best=width
            sum-=v[left+2];left+=1
    return Int64(best if best<=Int(count) else 0)
