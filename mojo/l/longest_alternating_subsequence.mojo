from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_alternating_subsequence")
fn longest_alternating_subsequence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>512 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var up=InlineArray[Int64,512](fill=0);var down=InlineArray[Int64,512](fill=0);var best:Int64=1
    for i in range(Int(n)):
        if v[i] < -2147483648 or v[i]>2147483647:return -1
        up[i]=1;down[i]=1
        for j in range(i):
            if v[j]<v[i] and up[i]<down[j]+1:up[i]=down[j]+1
            if v[j]>v[i] and down[i]<up[j]+1:down[i]=up[j]+1
        best=max(best,max(up[i],down[i]))
    return best
