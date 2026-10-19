from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("density")
fn density(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1.0e300
    let n=input[0];let edges=input[1];let directed=input[2]
    if n<2 or n>100000 or (directed!=0 and directed!=1):return -1.0e300
    let maxedges= n*(n-1) if directed==1 else n*(n-1)/2
    if edges<0 or edges>maxedges:return -1.0e300
    let factor=1.0 if directed==1 else 2.0
    return (factor*Float64(edges))/(Float64(n)*Float64(n-1))
