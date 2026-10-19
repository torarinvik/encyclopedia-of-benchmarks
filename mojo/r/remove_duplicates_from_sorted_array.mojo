from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr32(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt32(Int32(x))
    for j in range(4):o[at+j]=UInt8((b>>(j*8))&UInt32(255))
@export("remove_duplicates_from_sorted_array")
fn remove_duplicates_from_sorted_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let size=Int(n);var count=0
    for i in range(size):let x=v[i];if x< -2147483648 or x>2147483647 or (i>0 and v[i-1]>x):return -1
    for i in range(size):if i==0 or v[i]!=v[i-1]:count+=1
    if cap<c_size_t(count*4) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var w=0
    for i in range(size):if i==0 or v[i]!=v[i-1]:wr32(o,w*4,v[i]);w+=1
    return Int64(w)
