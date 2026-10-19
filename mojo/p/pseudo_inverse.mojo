from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt, fabs, trunc, isfinite
@export("pseudo_inverse")
fn pseudo_inverse(input:UnsafePointer[Float64,ImmutAnyOrigin],input_length:c_size_t,output:UnsafePointer[Float64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Float64,ImmutAnyOrigin]() or input_length<3 or input_length>6:return -1
    for i in range(Int(input_length)):if !isfinite(input[i]):return -1
    if input[0]<1 or input[0]>4 or input[0]!=trunc(input[0]) or input[1]!=1:return -1
    let rows=Int(input[0])
    if input_length!=c_size_t(2+rows):return -1
    var norm=Float64(0.0);var col=InlineArray[Float64,4](fill=0)
    for r in range(rows):
        let v=input[2+r]
        if v< -4 or v>4 or v!=trunc(v):return -1
        col[r]=v;norm+=v*v
    let singular=sqrt(norm);var staged=InlineArray[Float64,6](fill=0);staged[0]=1;staged[1]=Float64(rows)
    for r in range(rows):staged[2+r]=fabs(singular*col[r]/norm) if singular>=1e-4 and norm!=0 else 0.0
    if output==UnsafePointer[Float64,MutAnyOrigin]() or capacity<c_size_t(rows+2):return -2
    for i in range(rows+2):output[i]=staged[i]
    return Int64(rows+2)
