from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr32n(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt32(Int32(x));for j in range(4):o[at+j]=UInt8((b>>(j*8))&UInt32(255))
@export("remove_nth_node_from_end_of_list")
fn remove_nth_node_from_end_of_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1025:return -1
    let size=Int(n)-1;let pos=v[0];if pos<1 or pos>Int64(size):return -1
    for i in range(size):let x=v[i+1];if x< -2147483648 or x>2147483647:return -1
    let remove=size-Int(pos);let count=size-1
    if cap<c_size_t(count*4) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var w=0
    for i in range(size):if i!=remove:wr32n(o,w*4,v[i+1]);w+=1
    return Int64(w)
