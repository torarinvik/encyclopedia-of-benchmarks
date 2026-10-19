from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import pow,sqrt
@export("real_and_reactive_power")
fn real_and_reactive_power(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1.0e300
    let op=v[0];let apparent=v[1];let units=v[2]
    if (op!=0 and op!=1) or apparent < -1000000000 or apparent>1000000000 or units < -10000 or units>10000:return -1.0e300
    let pf=Float64(units)/10000.0
    if op==0:return Float64(apparent)*pf
    return Float64(apparent)*sqrt(1.0-pow(pf,2.0))
