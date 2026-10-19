from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("swap_pairs")
fn swap_pairs(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>1024 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]< -2147483648 or v[i]>2147483647:return -1
    let bytes=Int(n)*4
    if cap<c_size_t(bytes) or (bytes>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var staged=InlineArray[UInt8,4096](fill=0)
    for i in range(Int(n)):
        let pair=(i/2)*2
        let source=pair+1 if i%2==0 and pair+1<Int(n) else pair
        let bits=bitcast[UInt32](Int32(v[source]))
        for b in range(4):staged[i*4+b]=UInt8((bits>>UInt(b*8))&255)
    for i in range(bytes):out[i]=staged[i]
    return bytes
