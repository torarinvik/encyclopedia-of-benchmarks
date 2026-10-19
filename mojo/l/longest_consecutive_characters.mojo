from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("longest_consecutive_characters")
fn longest_consecutive_characters(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257 or v[0]<1 or v[0]>256 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0])
    for i in range(count):
        if v[i+1]<0 or v[i+1]>127:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<3:return -2
    var bestchar=v[1];var best=1;var cur=1
    for i in range(1,count):
        if v[i+1]==v[i]:
            cur+=1
            if cur>best:best=cur;bestchar=v[i+1]
        else:cur=1
    out[0]=UInt8(bestchar);out[1]=UInt8(best&255);out[2]=UInt8(best>>8)
    return 3
