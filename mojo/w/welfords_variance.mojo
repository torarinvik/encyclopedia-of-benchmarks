from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("welfords_variance")
fn welfords_variance(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>64:return -1.0e300
    var mean:Float64=0.0;var m2:Float64=0.0;var count=0
    for i in range(Int(n)):
        if a[i]< -1000000 or a[i]>1000000:return -1.0e300
        count+=1;let x=Float64(a[i]);let delta=x-mean;mean+=delta/Float64(count);m2+=delta*(x-mean)
    return m2/Float64(count-1)
