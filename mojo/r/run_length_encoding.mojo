from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("run_length_encoding")
fn run_length_encoding(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>66 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<1 or v[i]>127 or (v[i]>=48 and v[i]<=57):return -1
    var needed=0;var i=0
    while i<Int(n):
        var end=i+1
        while end<Int(n) and v[end]==v[i]:end+=1
        let count=end-i;needed+=if count>=10:3 else:2;i=end
    if cap<c_size_t(needed) or (needed>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var w=0;i=0
    while i<Int(n):
        var end=i+1
        while end<Int(n) and v[end]==v[i]:end+=1
        let count=end-i
        if count>=10:o[w]=UInt8(48+count/10);w+=1
        o[w]=UInt8(48+count%10);w+=1;o[w]=UInt8(v[i]);w+=1;i=end
    return Int64(w)
