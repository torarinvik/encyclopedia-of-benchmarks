from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("price_plus_tax")
fn price_plus_tax(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<0 or v[0]>1000000000000 or v[1]<0 or v[1]>1000000:return -1.0e300
    return (Float64(v[0])/1000000.0)*(1.0+Float64(v[1])/1000000.0)
