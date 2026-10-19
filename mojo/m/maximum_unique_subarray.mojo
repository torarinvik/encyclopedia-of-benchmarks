from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("maximum_unique_subarray")
fn maximum_unique_subarray(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var keys=InlineArray[Int64,512](fill=0);var last=InlineArray[Int,512](fill=0);var used=InlineArray[Bool,512](fill=False);var left=0;var sum:Int64=0;var best:Int64=0
    for i in range(Int(n)):
        let x=v[i];if x<1 or x>10000:return -1
        var slot=Int(x%512);while used[slot] and keys[slot]!=x:slot=(slot+1)%512
        let previous=last[slot]
        while left<previous:sum-=v[left];left+=1
        sum+=x;keys[slot]=x;used[slot]=True;last[slot]=i+1
        if sum>best:best=sum
    return best
