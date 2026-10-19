from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import abs

@export("mean_absolute_error_loss")
fn mean_absolute_error_loss(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>513:return -1.0e300
    let count=v[0];if count<1 or count>256 or n!=c_size_t(2*count+1):return -1.0e300
    var total=0.0
    for i in range(Int(count)):
        let predicted=v[i+1];let actual=v[Int(count)+i+1]
        if predicted< -1000000 or predicted>1000000 or actual< -1000000 or actual>1000000:return -1.0e300
        total+=abs(Float64(predicted-actual))
    return total/Float64(count)
