from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("z_function")
fn z_function(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -1
    let bytes=Int(n)*8
    if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var z=InlineArray[Int64,256](fill=0);var left=0;var right=0
    for i in range(1,Int(n)):
        if i<=right:z[i]=Int64(min(right-i+1,Int(z[i-left])))
        while i+Int(z[i])<Int(n) and v[Int(z[i])]==v[i+Int(z[i])]:z[i]+=1
        if i+Int(z[i])>right+1:left=i;right=i+Int(z[i])-1
    for i in range(Int(n)):
        for b in range(8):o[8*i+b]=UInt8((z[i]>>(8*b))&255)
    return Int64(bytes)
