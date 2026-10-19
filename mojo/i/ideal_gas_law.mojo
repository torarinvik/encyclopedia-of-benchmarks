from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("ideal_gas_law")
fn ideal_gas_law(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=4:return -1.0e300
    let op=input[0];let a=input[1];let b=input[2];let c=input[3]
    if op<0 or op>3 or a<0 or a>1000 or b<0 or b>1000 or c<0 or c>1000:return -1.0e300
    if op<2:
        if c==0:return -1.0e300
        return (Float64(a)*Float64(b)*8.314462)/Float64(c)
    if a==0:return -1.0e300
    return (Float64(c)*Float64(b))/(Float64(a)*8.314462)
