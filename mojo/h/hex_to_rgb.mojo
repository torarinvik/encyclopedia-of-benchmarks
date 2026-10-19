from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hex_to_rgb")
fn hex_to_rgb(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=6:return -1
    var v:Int64=0
    for i in range(6):
        let c=a[i];var d:Int64=-1
        if c>=48 and c<=57:d=c-48
        elif c>=65 and c<=70:d=c-55
        elif c>=97 and c<=102:d=c-87
        if d<0:return -1
        v=v*16+d
    return v
