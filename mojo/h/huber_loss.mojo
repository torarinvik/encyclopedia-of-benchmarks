from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("huber_loss")
fn huber_loss(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1.0e300
    let delta=Float64(a[0])/1.0e6;let nt=a[1];let np=a[2]
    if delta<0.0 or delta>1000.0 or nt<1 or nt>65 or np<1 or np>65 or nt!=np or n!=c_size_t(3+nt+np) or nt>64:return -1.0e300
    var sum=0.0
    for i in range(Int(nt)):
        let x=Float64(a[3+i])/1.0e6;let y=Float64(a[3+Int(nt)+i])/1.0e6
        if abs(x)>1000.0 or abs(y)>1000.0:return -1.0e300
        let r=abs(x-y);sum+=0.5*r*r if r<=delta else delta*r-0.5*delta*delta
    return sum/Float64(nt)
