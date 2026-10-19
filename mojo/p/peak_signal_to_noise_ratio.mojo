from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("peak_signal_to_noise_ratio")
fn peak_signal_to_noise_ratio(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>129 or v[0]<1 or v[0]>64 or Int(n)!=1+2*Int(v[0]):return -1.0e300
    let count=Int(v[0]);var sum=0.0
    for i in range(count):
        let a=v[1+i];let b=v[1+count+i];if a<0 or a>255 or b<0 or b>255 or a-b < -15 or a-b>15:return -1.0e300
        let d=Float64(a)-Float64(b);sum+=d*d
    let mse=sum/Float64(count);if mse==0.0:return -1.0e300
    return 20.0*log10(255.0/sqrt(mse))
