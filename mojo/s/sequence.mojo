from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn seq_term(n:Int)->Int64:
    if n==0 or n==1:return Int64(n)
    if n%2==0:return 4*seq_term(n/2)
    return 4*seq_term(n/2)+1
@export("sequence")
fn sequence(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or a[0]< -64 or a[0]>64:return -1
    if a[0]<=0:return 0
    let count=Int(a[0]);let bytes=count*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):
        let z=bitcast[UInt64](seq_term(i));for b in range(8):o[i*8+b]=UInt8((z>>UInt(8*b))&255)
    return Int64(bytes)
