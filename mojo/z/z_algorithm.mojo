from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("z_algorithm")
fn z_algorithm(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>2048:return -1
    let count=v[0]
    if count<0 or count>2047 or n!=c_size_t(count+1):return -1
    let bytes=Int(count)*4
    if cap<c_size_t(bytes) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var z=InlineArray[Int,2047](fill=0);var left=0;var right=0
    for i in range(1,Int(count)):
        if i<right:z[i]=min(z[i-left],right-i)
        while i+z[i]<Int(count) and v[1+z[i]]==v[1+i+z[i]]:z[i]+=1
        if i+z[i]>right:left=i;right=i+z[i]
    for i in range(Int(count)):
        let x=UInt32(z[i])
        for b in range(4):o[4*i+b]=UInt8((x>>(8*b))&255)
    return count
