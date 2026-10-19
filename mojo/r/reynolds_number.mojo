from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("reynolds_number")
fn reynolds_number(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1.0e300
    let density=v[0];let velocity=v[1];let diameter=v[2];let viscosity=v[3]
    if density<1 or density>1000 or velocity< -1000 or velocity>1000 or diameter<1 or diameter>1000 or viscosity<1 or viscosity>1000:return -1.0e300
    let speed=if velocity<0:-velocity else:velocity
    return ((Float64(density)*Float64(speed))*Float64(diameter))/Float64(viscosity)
