from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import sqrt
@export("lorentz_transformation_four_vector")
fn lorentz_transformation_four_vector(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=6:return -1.0e300
    let velocity=v[0];let selector=v[1];let time=v[2];let x=v[3];let y=v[4];let z=v[5]
    if velocity<1 or velocity>200000000 or selector<0 or selector>3 or time < -1000000 or time>1000000 or x < -100000000 or x>100000000 or y < -100000000 or y>100000000 or z < -100000000 or z>100000000:return -1.0e300
    let beta=Float64(velocity)/299792458.0;let gamma=1.0/sqrt(1.0-beta*beta);let ct=(Float64(time)/1.0e6)*299792458.0;let xx=Float64(x)/100.0;let yy=Float64(y)/100.0;let zz=Float64(z)/100.0
    let a=gamma*ct-gamma*beta*xx;let b= -gamma*beta*ct+gamma*xx
    return if selector==0:a elif selector==1:b elif selector==2:yy else:zz
