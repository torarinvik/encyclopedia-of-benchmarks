from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("subset_sum_exists")
fn subset_sum_exists(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>25:return -1
    let target=v[0]
    if target< -6144 or target>6144:return -1
    for i in range(1,Int(n)):if v[i]< -256 or v[i]>256:return -1
    var reach=InlineArray[Bool,12289](fill=False);reach[6144]=True;var low=0;var high=0
    for i in range(1,Int(n)):
        let x=v[i]
        if x>0:
            var s=high
            while s>=low:
                if reach[s+6144]:reach[s+x+6144]=True
                s-=1
            high+=x
        elif x<0:
            for s in range(low,high+1):if reach[s+6144]:reach[s+x+6144]=True
            low+=x
    return 1 if reach[target+6144] else 0
