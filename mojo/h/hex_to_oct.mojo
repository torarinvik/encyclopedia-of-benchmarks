from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn hto_wrap(v:Int64)->Int64:return Int64(bitcast[Int32](UInt32(bitcast[UInt32](Int32(v)))))
@export("hex_to_oct")
fn hex_to_oct(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>8 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -2147483649
    var value:Int64=0
    for i in range(Int(n)):
        let c=a[i];var d:Int64=-1
        if c>=48 and c<=57:d=c-48
        elif c>=65 and c<=70:d=c-55
        elif c>=97 and c<=102:d=c-87
        if d<0:return -2147483649
        value=hto_wrap(value*16+d)
    var oct:Int64=0;var place:Int64=1;var x=value
    while x>0:oct=hto_wrap(oct+(x%8)*place);place=hto_wrap(place*10);x/=8
    return oct
