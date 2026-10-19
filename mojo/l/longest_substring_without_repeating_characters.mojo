from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_substring_without_repeating_characters")
fn longest_substring_without_repeating_characters(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>1024 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -2
    var last=InlineArray[Int64,95](fill=-1);var start=0;var best=0
    for i in range(Int(n)):
        let x=v[i]
        if x<32 or x>126:return -2
        let slot=Int(x-32)
        if last[slot]>=0 and Int(last[slot])>=start:start=Int(last[slot])+1
        last[slot]=Int64(i);best=max(best,i-start+1)
    return Int64(best)
