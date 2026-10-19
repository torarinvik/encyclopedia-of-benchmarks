from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64= -1.0e300
@export("sparsity")
fn sparsity(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>3971:return BAD
    let rv=v[0];let cv=v[1]
    if rv<1 or rv>63 or cv<1 or cv>63:return BAD
    let rows=Int(rv);let cols=Int(cv);let cells=rows*cols
    if n!=c_size_t(2+cells):return BAD
    var zero=0
    for i in range(cells):
        let x=v[2+i]
        if x< -1000000 or x>1000000:return BAD
        if x==0:zero+=1
    return Float64(zero)/Float64(cells)
