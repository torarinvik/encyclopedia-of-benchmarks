from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import sqrt
@export("relativistic_kinetic_energy")
fn relativistic_kinetic_energy(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1.0e300
    let mass=v[0];let velocity=v[1];let c:Int64=299792458
    if mass<0 or mass>1000000 or velocity<-(c-1) or velocity>c-1:return -1.0e300
    let gamma=1.0/sqrt(1.0-Float64(velocity*velocity)/Float64(c*c))
    return (gamma-1.0)*Float64(mass)*Float64(c*c)
