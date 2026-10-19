from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("xor_linked_list")
fn xor_linked_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>66:return -1
    let count=v[0]
    if count<0 or count>64 or n!=c_size_t(count+1):return -1
    for i in range(Int(count)):if v[i+1]< -2147483648 or v[i+1]>2147483647:return -1
    let bytes=8+8*Int(count)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var vals=InlineArray[Int64,65](fill=0);var both=InlineArray[Int,65](fill=0);var tail=0
    for i in range(Int(count)):
        let node=i+1;vals[node]=v[i+1];both[node]=tail
        if tail!=0:both[tail]=both[tail]^node
        tail=node
    for b in range(8):o[b]=UInt8((count>>(8*b))&255)
    var output_at=8;var previous=0;var current=1 if count>0 else 0
    while current!=0:
        let next=both[current]^previous
        for b in range(8):o[output_at+b]=UInt8((vals[current]>>(8*b))&255)
        output_at+=8;previous=current;current=next
    return Int64(bytes)
