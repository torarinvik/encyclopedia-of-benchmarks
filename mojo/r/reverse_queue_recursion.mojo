from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn rec_queue(v:UnsafePointer[Int64,ImmutAnyOrigin],o:UnsafePointer[UInt8,MutAnyOrigin],n:Int,i:Int):
    if i>=n:return
    rec_queue(v,o,n,i+1);o[n-1-i]=UInt8(v[i+1])
@export("reverse_queue_recursion")
fn reverse_queue_recursion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]():
        if n!=1:return -1
        if o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
        return 0
    if n<1 or n>34:return -1
    if v[0]<0 or v[0]>32 or Int(n)!=Int(v[0])+1:return -1
    let size=Int(v[0]);for i in range(size):if v[i+1]<0 or v[i+1]>255:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(size):return -2
    rec_queue(v,o,size,0);return Int64(size)
