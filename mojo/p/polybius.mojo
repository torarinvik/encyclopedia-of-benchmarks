from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("polybius")
fn polybius(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65 or v[0]<0 or v[0]>64 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0]);let need=count*2
    if cap<c_size_t(need) or (need>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(count):
        var ch=v[i+1]
        if ch>=97 and ch<=122:ch-=32
        if ch<65 or ch>90 or ch==74:return -1
        var ix=Int(ch-65)
        if ch>74:ix-=1
        out[2*i]=UInt8(65+ix//5);out[2*i+1]=UInt8(65+ix%5)
    return Int64(need)
