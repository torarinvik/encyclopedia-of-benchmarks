from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("lens_formulae")
fn lens_formulae(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1.0e300
    let op=v[0];let a=v[1];let b=v[2]
    if op<0 or op>2 or a==0 or b==0 or a < -1000000 or a>1000000 or b < -1000000 or b>1000000:return -1.0e300
    if op<2:
        if a==b:return -1.0e300
        return 1.0/((1.0/Float64(b))-(1.0/Float64(a)))
    if a== -b:return -1.0e300
    return 1.0/((1.0/Float64(b))+(1.0/Float64(a)))
