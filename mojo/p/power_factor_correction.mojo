from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sin, acos
@export("power_factor_correction")
fn power_factor_correction(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=6:return -1.0e300
    let op=v[0];let voltage=v[1];let freq=v[2];let power=v[3];let cb=v[4];let eb=v[5]
    if (op!=0 and op!=1) or voltage<1 or voltage>1000 or freq<1 or freq>1000 or power< -1000000 or power>1000000 or cb< -10000 or cb>10000 or eb< -10000 or eb>10000 or cb==0 or eb==0 or (op==1 and cb==eb):return -1.0e300
    let c=Float64(cb)/10000.0;let e=Float64(eb)/10000.0;let p=Float64(power)
    let oldq=(p/c)*sin(acos(c));let newq=(p/e)*sin(acos(e));let dq=oldq-newq
    let vv=Float64(voltage);let denom=2.0*3.14159265358979323846*Float64(freq)
    return dq/(denom*(vv*vv)) if op==0 else (vv*vv)/(denom*dq)
