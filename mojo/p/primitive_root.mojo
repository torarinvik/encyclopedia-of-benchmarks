from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("primitive_root")
fn primitive_root(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<2 or v[0]>127:return -1
    let m=Int(v[0])
    for candidate in range(1,m):
        var seen=InlineArray[Bool,127](fill=False);var power=1;var good=True
        for _ in range(m-1):
            if seen[power]:good=False;break
            seen[power]=True;power=(power*candidate)%m
        if good:return Int64(candidate)
    return 0
