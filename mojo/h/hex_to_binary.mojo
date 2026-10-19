from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("hex_to_binary")
fn hex_to_binary(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    if cap<c_size_t(n*4) or (n>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(Int(n)):
        let c=a[i];var d=-1
        if c>=48 and c<=57:d=Int(c-48)
        elif c>=65 and c<=70:d=Int(c-55)
        elif c>=97 and c<=102:d=Int(c-87)
        if d<0:return -1
    let bits=InlineArray[UInt8,16](fill=48)
    for i in range(Int(n)):
        let c=a[i];var d=Int(c-48)
        if c>=65 and c<=70:d=Int(c-55)
        elif c>=97 and c<=102:d=Int(c-87)
        for b in range(4):out[i*4+b]=UInt8(48+((d>>(3-b))&1))
    return Int64(n*4)
