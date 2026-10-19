from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mz_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int64):
    let u=UInt32(Int32(x))
    for b in range(4):o[4*p+b]=UInt8((u>>(8*b))&255)
@export("move_zeroes")
fn move_zeroes(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n!=0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i] < -2147483648 or v[i]>2147483647:return -1
    let bytes=4*Int(n);if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var w=0
    for i in range(Int(n)):if v[i]!=0:mz_put(o,w,v[i]);w+=1
    while w<Int(n):mz_put(o,w,0);w+=1
    return Int64(n)
