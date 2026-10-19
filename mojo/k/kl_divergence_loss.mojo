from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import log
@export("kl_divergence_loss")
fn kl_divergence_loss(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130:return -1.0e300
    let ac=a[0];let pc=a[1]
    if ac<0 or ac>64 or pc<0 or pc>64 or n!=c_size_t(2+ac+pc):return -1.0e300
    for i in range(Int(2+ac+pc)):if i>=2 and (a[i]<0 or a[i]>1000000):return -1.0e300
    let m=min(ac,pc);var total:Float64=0.0
    for i in range(Int(m)):
        let actual=Float64(a[2+i])/1000000.0+1e-5;let pred=Float64(a[2+Int(ac)+i])/1000000.0+1e-5
        total+=actual*log(actual/pred)
    return total
