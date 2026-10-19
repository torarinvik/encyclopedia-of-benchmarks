from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
@export("good_pairs_hash")
fn good_pairs_hash(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>258 or v[0]<0 or v[0]>256 or n!=c_size_t(v[0]+1):return -1
    var keys=InlineArray[Int64,512](fill=0);var freq=InlineArray[UInt64,512](fill=0);var used=InlineArray[Bool,512](fill=False)
    for i in range(Int(v[0])):
        let x=v[i+1];if x< -1000000 or x>1000000:return -1
        var slot=Int((UInt64(x+1000000)*UInt64(2654435761))&511)
        while used[slot] and keys[slot]!=x:slot=(slot+1)&511
        if not used[slot]:used[slot]=True;keys[slot]=x
        freq[slot]+=1
    var pairs:UInt64=0
    for i in range(512):if freq[i]>1:pairs+=freq[i]*(freq[i]-1)//2
    return Int64(pairs)
