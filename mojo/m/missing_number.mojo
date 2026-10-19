from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("missing_number")
fn missing_number(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>1024 or (n!=0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var seen=InlineArray[Int64,1025](fill=0);var actual:Int64=0
    for i in range(Int(n)):
        let x=v[i]
        if x<0 or x>=Int64(n)+1:return -1
        if seen[Int(x)]!=0:return -1
        seen[Int(x)]=1;actual+=x
    let count=Int64(n)
    return count*(count+1)/2-actual
