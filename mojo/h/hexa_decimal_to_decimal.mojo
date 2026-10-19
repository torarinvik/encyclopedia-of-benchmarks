from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hexa_decimal_to_decimal")
fn hexa_decimal_to_decimal(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>65 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -2147483649
    var v:UInt32=0
    for i in range(Int(n)):
        let c=a[i];var d:Int64=-1
        if c>=48 and c<=57:d=c-48
        elif c>=65 and c<=70:d=c-55
        elif c>=97 and c<=102:d=c-87
        if d<0:return -2147483649
        v=v*16+UInt32(d)
    return Int64(bitcast[Int32](v))
