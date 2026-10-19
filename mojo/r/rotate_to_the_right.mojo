from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr64rr(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x);for j in range(8):o[at+j]=UInt8((b>>(8*j))&UInt64(255))
@export("rotate_to_the_right")
fn rotate_to_the_right(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>68 or v[0]<1 or v[0]>64 or v[1]< -1000000 or v[1]>1000000 or Int(n)!=Int(v[0])+2:return -1
    let size=Int(v[0]);for i in range(size):if v[i+2]< -2147483648 or v[i+2]>2147483647:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(size*8):return -2
    let shift=Int(((v[1]%Int64(size))+Int64(size))%Int64(size))
    for i in range(size):wr64rr(o,8*i,v[2+(i+size-shift)%size])
    return Int64(size*8)
