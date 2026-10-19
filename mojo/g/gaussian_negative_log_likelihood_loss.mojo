from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import log

@export("gaussian_negative_log_likelihood_loss")
fn gaussian_negative_log_likelihood_loss(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>769:return -1.0e300
    let count=Int(v[0]);if count<1 or count>256 or n!=c_size_t(1+3*count):return -1.0e300
    var total=0.0
    for i in range(count):
        let ys=v[1+i];let ms=v[1+count+i];let vn=v[1+2*count+i]
        if ys< -1000000 or ys>1000000 or ms< -1000000 or ms>1000000 or vn<1 or vn>1000000000:return -1.0e300
        let y=Float64(ys)/1000000.0;let mu=Float64(ms)/1000000.0
        var variance=Float64(vn)/1000000000.0;if variance<1.0e-6:variance=1.0e-6
        let residual=y-mu;let lossvar=0.5*log(variance);let losse=0.5*((residual*residual)/variance)
        total+=lossvar+losse
    return total/Float64(count)
