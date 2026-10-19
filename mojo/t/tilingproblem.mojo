from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("tilingproblem")
fn tilingproblem(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1:return -1
    let width=a[0]
    if width<0 or width>91:return -1
    if width<2:return 1
    var x:Int64=1;var y:Int64=1
    for _ in range(2,Int(width)+1):let z=x+y;x=y;y=z
    return y
