from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import log
@export("kullback_leibler_divergence")
fn kullback_leibler_divergence(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>129 or a[0]<1 or a[0]>64 or n!=c_size_t(1+2*a[0]):return -1.0e300
    let count=Int(a[0]);var total:Float64=0.0
    for i in range(count):
        let t=a[1+i];let p=a[1+count+i]
        if t<0 or t>1000000 or p<0 or p>1000000 or (t>0 and p==0):return -1.0e300
        if t>0:
            let target=Float64(t)/1000000.0;let pred=Float64(p)/1000000.0;total+=target*log(target/pred)
    return total
