from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("huber_loss_math")
fn huber_loss_math(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1.0e300
    let delta=Float64(a[0])/1.0e6;let na=a[1];let np=a[2]
    if delta<0.0 or delta>1000.0 or na<0 or na>65 or np<0 or np>65 or n!=c_size_t(3+na+np) or na>64 or np>64:return -1.0e300
    for i in range(Int(na)+Int(np)):if abs(Float64(a[3+i])/1.0e6)>1000.0:return -1.0e300
    let pairs=min(na,np);var sum=0.0
    for i in range(Int(pairs)):
        let d=abs(Float64(a[3+i]-a[3+Int(na)+i])/1.0e6)
        sum+=0.5*d*d if d<=delta else delta*d-delta/2.0
    return sum
