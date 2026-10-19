from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr32rr(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt32(Int32(x));for j in range(4):o[at+j]=UInt8((b>>(8*j))&UInt32(255))
fn recursive_rev(v:UnsafePointer[Int64,ImmutAnyOrigin],o:UnsafePointer[UInt8,MutAnyOrigin],n:Int,index:Int)->Int:
    if index>=n:return 0
    let sub=recursive_rev(v,o,n,index+1);wr32rr(o,sub*4,v[index+1]);return sub+1
@export("reverse_a_linked_list_using_recusion")
fn reverse_a_linked_list_using_recusion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>65 or v[0]<2 or v[0]>64 or Int(n)!=Int(v[0])+1:return -1
    let size=Int(v[0]);for i in range(size):if v[i+1]< -2147483648 or v[i+1]>2147483647:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(4*size):return -2
    recursive_rev(v,o,size,0)
    return Int64(4*size)
