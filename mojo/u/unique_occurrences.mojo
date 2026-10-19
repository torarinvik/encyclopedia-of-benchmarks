from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("unique_occurrences")
fn unique_occurrences(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>1000 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var counts=InlineArray[Int,2001](fill=0)
    for i in range(Int(n)):
        if v[i]< -1000 or v[i]>1000:return -1
        counts[Int(v[i]+1000)]+=1
    var seen=InlineArray[UInt8,1001](fill=0)
    for i in range(2001):
        let c=counts[i]
        if c>0:
            if seen[c]!=0:return 0
            seen[c]=1
    return 1
