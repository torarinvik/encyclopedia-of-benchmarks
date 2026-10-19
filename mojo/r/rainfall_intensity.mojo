from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import pow
@export("rainfall_intensity")
fn rainfall_intensity(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=6:return -1.0e300
    let k=v[0];let a=v[1];let b=v[2];let c=v[3];let period=v[4];let duration=v[5]
    if k<1 or k>1000 or a<1 or a>3 or b<1 or b>100 or c<1 or c>3 or period<1 or period>100 or duration<1 or duration>1000:return -1.0e300
    return (Float64(k)*pow(Float64(period),Float64(a)))/pow(Float64(duration+b),Float64(c))
