from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minimum_sum_partition")
fn minimum_sum_partition(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>64 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var total=0
    for i in range(Int(n)):
        if v[i]<0 or v[i]>4096:return -1
        total+=Int(v[i])
    if total>4096:return -1
    var possible=InlineArray[Int64,4097](fill=0);possible[0]=1
    for i in range(Int(n)):
        let x=Int(v[i])
        for s in range(total,x-1,-1):if possible[s-x]!=0:possible[s]=1
    var best=total
    for s in range(total+1):if possible[s]!=0:
        let diff=total-2*s;let abs=if diff<0:-diff else:diff
        if abs<best:best=abs
    return Int64(best)
