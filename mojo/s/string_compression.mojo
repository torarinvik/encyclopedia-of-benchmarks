from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("string_compression")
fn string_compression(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>64 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -1
    var needed=0;var i=0
    while i<Int(n):
        var end=i+1
        while end<Int(n) and v[end]==v[i]:end+=1
        let count=end-i;needed+=1+(if count>1 then (if count>=10 then 2 else 1) else 0);i=end
    if cap<c_size_t(needed) or (needed>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var p=0;i=0
    while i<Int(n):
        var end=i+1
        while end<Int(n) and v[end]==v[i]:end+=1
        let count=end-i;o[p]=UInt8(v[i]);p+=1
        if count>1:
            if count>=10:o[p]=UInt8(48+count/10);p+=1
            o[p]=UInt8(48+count%10);p+=1
        i=end
    return Int64(p)
