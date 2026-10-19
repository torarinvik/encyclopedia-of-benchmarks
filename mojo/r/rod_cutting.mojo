from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("rod_cutting")
fn rod_cutting(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>31 or v[0]<1 or v[0]>30 or Int(n)!=Int(v[0])+1:return -1
    let size=Int(v[0]);for i in range(size):if v[i+1]<1 or v[i+1]>1000:return -1
    var best=InlineArray[Int64,31](fill=0)
    for rod in range(1,size+1):
        var value:Int64=0
        for cut in range(1,rod+1):let candidate=v[cut]+best[rod-cut];if candidate>value:value=candidate
        best[rod]=value
    return best[size]
