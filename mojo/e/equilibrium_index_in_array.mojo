from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("equilibrium_index_in_array")
fn equilibrium_index_in_array(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>1025:return -2
    let n=values[0]
    if n<0 or n>1024 or length!=c_size_t(n+1):return -2
    var total:Int64=0
    for i in range(Int(n)):
        let v=values[i+1]
        if v< -2147483648 or v>2147483647:return -2
        total+=v
    var left:Int64=0
    for i in range(Int(n)):
        total-=values[i+1]
        if left==total:return i
        left+=values[i+1]
    return -1
