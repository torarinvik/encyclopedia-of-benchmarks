from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn hanoi_emit(disks:Int,src:UInt8,dst:UInt8,aux:UInt8,out:UnsafePointer[UInt8,MutAnyOrigin],inout pos:Int):
    if disks==0:return
    hanoi_emit(disks-1,src,aux,dst,out,pos)
    out[pos]=src;out[pos+1]=dst;pos+=2
    hanoi_emit(disks-1,aux,dst,src,out,pos)
@export("tower_of_hanoi")
fn tower_of_hanoi(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4 or a[0]<0 or a[0]>12:return -1
    for i in range(1,4):
        if a[i]<0 or a[i]>2:return -1
    if a[1]==a[2] or a[1]==a[3] or a[2]==a[3]:return -1
    let moves=(1<<Int(a[0]))-1;let bytes=moves*2
    if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var pos=0;hanoi_emit(Int(a[0]),UInt8(a[1]),UInt8(a[2]),UInt8(a[3]),o,pos)
    return Int64(moves)
