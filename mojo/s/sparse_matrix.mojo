from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("sparse_matrix")
fn sparse_matrix(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>4099:return -1
    let rv=v[0];let cv=v[1]
    if rv<1 or rv>64 or cv<1 or cv>64:return -1
    let cells=Int(rv*cv)
    if n!=c_size_t(2+cells):return -1
    var zero=0
    for i in range(cells):
        let x=v[2+i]
        if x< -2147483648 or x>2147483647:return -1
        if x==0:zero+=1
    return 1 if zero>cells/2 else 0
