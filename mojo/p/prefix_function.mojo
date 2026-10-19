from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("prefix_function")
fn prefix_function(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>4097 or v[0]<0 or v[0]>4096 or n!=c_size_t(v[0]+1):return -1
    let len=Int(v[0])
    for i in range(len):if v[i+1]<0 or v[i+1]>127:return -1
    let bytes=len*4
    if cap<c_size_t(bytes) or (bytes>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var pi=InlineArray[Int32,4096](fill=0)
    for i in range(1,len):
        var j=Int(pi[i-1])
        while j>0 and v[i+1]!=v[j+1]:j=Int(pi[j-1])
        if v[i+1]==v[j+1]:j+=1
        pi[i]=Int32(j)
    for i in range(len):
        let bits=UInt32(pi[i])
        for b in range(4):out[i*4+b]=UInt8((bits>>(8*b))&255)
    return Int64(bytes)
