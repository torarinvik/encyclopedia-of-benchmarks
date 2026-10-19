from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import sqrt
fn rel_gamma(v:Float64)->Float64:return 1.0/sqrt(1.0-v*v/(299792458.0*299792458.0))
@export("relativity")
fn relativity(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1.0e300
    let op=v[0];let a=v[1];let b=v[2];let c:Float64=299792458.0;let cm:Int64=299792458000
    if op==0:
        if b!=0 or a<= -cm or a>=cm:return -1.0e300
        return rel_gamma(Float64(a)/1000.0)
    if op==1 or op==2:
        if a<0 or a>1000000 or b<= -cm or b>=cm:return -1.0e300
        let q=Float64(a)/1000.0;let g=rel_gamma(Float64(b)/1000.0)
        return if op==1:q/g else:q*g
    if op==3:
        if a< -cm or a>cm or b<= -cm or b>=cm:return -1.0e300
        let x=Float64(a)/1000.0;let y=Float64(b)/1000.0
        return (x-y)/(1.0-x*y/(c*c))
    return -1.0e300
