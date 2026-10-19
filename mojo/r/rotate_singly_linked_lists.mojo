from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr64sl(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x);for j in range(8):o[at+j]=UInt8((b>>(8*j))&UInt64(255))
@export("rotate_singly_linked_lists")
fn rotate_singly_linked_lists(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66 or v[0]<0 or v[0]>64 or v[1]<0 or v[1]>2147483647 or Int(n)!=Int(v[0])+2:return -1
    let size=Int(v[0]);for i in range(size):if v[i+2]< -2147483648 or v[i+2]>2147483647:return -1
    let bytes=8*(size+1);if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    wr64sl(o,0,Int64(size));let shift=if size==0:0 else:Int(v[1]%Int64(size))
    for i in range(size):let src=(i+size-shift)%size;wr64sl(o,8*(i+1),v[2+src])
    return Int64(bytes)
