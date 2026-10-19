from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr32ra(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt32(Int32(x));for j in range(4):o[at+j]=UInt8((b>>(8*j))&UInt32(255))
@export("reverse_a_linked_list")
fn reverse_a_linked_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>128 or Int(n)!=Int(v[0])+1:return -1
    let size=Int(v[0]);for i in range(size):if v[i+1]< -2147483648 or v[i+1]>2147483647:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(4*size):return -2
    for i in range(size):wr32ra(o,4*i,v[size-i])
    return Int64(4*size)
