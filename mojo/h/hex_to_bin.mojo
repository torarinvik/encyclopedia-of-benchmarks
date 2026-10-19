from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hex_to_bin")
fn hex_to_bin(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n<1 or n>5 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -9223372036854775808
    var start=0;var sign=1
    if a[0]==45:start=1;sign=-1
    if Int(n)-start<1 or Int(n)-start>4:return -9223372036854775808
    var v=0
    for i in range(start,Int(n)):
        let c=a[i];var d=-1
        if c>=48 and c<=57:d=Int(c-48)
        elif c>=65 and c<=70:d=Int(c-55)
        elif c>=97 and c<=102:d=Int(c-87)
        if d<0:return -9223372036854775808
        v=v*16+d
    if v==0:return -9223372036854775808
    var out=0;var place=1;var x=v
    while x>0:out+=(x&1)*place;place*=10;x>>=1
    return Int64(out*sign)
