from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("mean_bias_deviation_percent")
fn mean_bias_deviation_percent(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>131:return -1.0e300
    let count=v[0];if count<1 or count>64 or n!=c_size_t(1+2*count):return -1.0e300
    var ds:Int64=0;var actual_sum:Int64=0
    for i in range(Int(count)):
        let pred=v[i+1];let actual=v[Int(count)+i+1]
        if pred< -1000 or pred>1000 or actual< -1000 or actual>1000:return -1.0e300
        ds+=pred-actual;actual_sum+=actual
    if actual_sum==0:return -1.0e300
    let numerator=Float64(ds)/Float64(count);let denominator=Float64(actual_sum)/Float64(count)
    return numerator/denominator*100.0
