from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import log
@export("negative_log_likelihood")
fn negative_log_likelihood(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or a[0]<1 or a[0]>64 or n!=c_size_t(1+2*a[0]):return -1.0e300
    let count=Int(a[0]);var total:Float64=0.0
    for i in range(count):
        let av=a[1+i];let pv=a[1+count+i]
        if av<0 or av>1000000 or pv<1 or pv>999999:return -1.0e300
        let actual=Float64(av)/1000000.0;let pred=Float64(pv)/1000000.0
        total+=-actual*log(pred)-(1.0-actual)*log(1.0-pred)
    return total/Float64(count)
