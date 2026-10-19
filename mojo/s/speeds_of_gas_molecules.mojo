from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64= -1.0e300
comptime GAS=8.31446261815324
comptime PI=3.14159265358979323846264338327950288
@export("speeds_of_gas_molecules")
fn speeds_of_gas_molecules(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>4:return BAD
    let op=v[0];let tm=v[1];let mm=v[2]
    if n!=3 or op<0 or op>1 or tm<0 or tm>1000000 or mm<1 or mm>1000000000:return BAD
    let t=Float64(tm)/1000.0;let m=Float64(mm)/1000000.0
    if op==0:return sqrt((8.0*GAS*t)/(PI*m))
    return sqrt((2.0*GAS*t)/m)
