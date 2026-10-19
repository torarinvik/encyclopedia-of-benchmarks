from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_arithmetic_subsequence")
fn longest_arithmetic_subsequence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>64 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if v[i] < -1000000 or v[i]>1000000:return -1
    if n<=1:return Int64(n)
    var keys=InlineArray[Int64,64*127](fill=0);var sizes=InlineArray[Int64,64*127](fill=0);var best:Int64=2
    for r in range(Int(n)):
        for l in range(r):
            let diff=v[r]-v[l];let hash=Int((diff%127+127)%127);var slot=l*127+hash
            while sizes[slot]!=0 and keys[slot]!=diff:slot=l*127+((slot-l*127+1)%127)
            let candidate=(if sizes[slot]==0:1 else:sizes[slot])+1
            slot=r*127+hash
            while sizes[slot]!=0 and keys[slot]!=diff:slot=r*127+((slot-r*127+1)%127)
            if sizes[slot]==0 or candidate>sizes[slot]:keys[slot]=diff;sizes[slot]=candidate
            if candidate>best:best=candidate
    return best
