from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("subset_sum_count")
fn subset_sum_count(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>25:return -1
    let target=v[0]
    if target< -6144 or target>6144:return -1
    for i in range(1,Int(n)):if v[i]< -256 or v[i]>256:return -1
    var ways=InlineArray[Int64,12289](fill=0);ways[6144]=1;var low=0;var high=0
    for i in range(1,Int(n)):
        let x=v[i]
        if x>0:
            var s=high
            while s>=low:ways[s+x+6144]+=ways[s+6144];s-=1
            high+=x
        elif x<0:
            for s in range(low,high+1):ways[s+x+6144]+=ways[s+6144]
            low+=x
        else:
            for s in range(low,high+1):ways[s+6144]*=2
    return ways[target+6144]
