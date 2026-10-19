from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("reverse_string_in_place")
fn reverse_string_in_place(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>255:return -1
    if cap<n or (n>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(Int(n)):o[i]=UInt8(v[i])
    var left=0;var right=Int(n)
    while left<right:
        right-=1
        if left>=right:break
        let t=o[left];o[left]=o[right];o[right]=t;left+=1
    return Int64(n)
