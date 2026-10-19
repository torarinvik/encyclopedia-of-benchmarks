from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("nearest_neighbor_interpolation")
fn nearest_neighbor_interpolation(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>258 or a[0]<1 or a[0]>16 or a[1]<1 or a[1]>16:return -1
    let rows=Int(a[0]);let cols=Int(a[1]);if n!=c_size_t(2+rows*cols):return -1
    for i in range(2,Int(n)):if a[i]<0 or a[i]>255:return -1
    let orows=3*rows//2;let ocols=3*cols//2;let need=orows*ocols
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(need):return -2
    for y in range(orows):
        let sy=(4*(y+1)+3)//6-1
        for x in range(ocols):let sx=(4*(x+1)+3)//6-1;o[y*ocols+x]=UInt8(a[2+sy*cols+sx])
    return need
