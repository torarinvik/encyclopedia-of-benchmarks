from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("remove_stars")
fn remove_stars(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>4097 or v[0]<0 or v[0]>4096 or Int(n)!=Int(v[0])+1:return -1
    var count=0
    for i in range(Int(v[0])):
        let x=v[i+1];if x<0 or x>127:return -1
        if x==42:if count>0:count-=1
        else:count+=1
    if cap<c_size_t(count) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var w=0
    for i in range(Int(v[0])):
        let x=v[i+1]
        if x==42:if w>0:w-=1
        else:o[w]=UInt8(x);w+=1
    return Int64(w)
