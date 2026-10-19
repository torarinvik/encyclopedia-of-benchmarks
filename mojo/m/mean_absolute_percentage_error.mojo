from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import abs

@export("mean_absolute_percentage_error")
fn mean_absolute_percentage_error(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return -1.0e300
    let count=v[0];if count<1 or count>64 or n!=c_size_t(1+2*count):return -1.0e300
    for i in range(Int(2*count)):if v[i+1]< -1000000 or v[i+1]>1000000:return -1.0e300
    var total=0.0
    for i in range(Int(count)):
        let truth=Float64(v[i+1])/1000000.0;let pred=Float64(v[Int(count)+i+1])/1000000.0
        let safe=1.0e-15 if truth==0.0 else truth
        total+=abs((safe-pred)/safe)
    return total/Float64(count)
