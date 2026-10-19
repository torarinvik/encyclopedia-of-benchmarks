from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("mean_square_error")
fn mean_square_error(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>513:return -1.0e300
    let count=v[0];if count<1 or count>256 or n!=c_size_t(2*count+1):return -1.0e300
    var error_sum=0.0
    for i in range(Int(count)):
        let pred=v[i+1];let expected=v[Int(count)+i+1]
        if pred< -1000000 or pred>1000000 or expected< -1000000 or expected>1000000:return -1.0e300
        let diff=Float64(expected-pred);error_sum+=diff*diff
    return error_sum/Float64(count)
