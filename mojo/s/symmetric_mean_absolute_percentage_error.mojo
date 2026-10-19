from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime INVALID_SMAPE:Float64= -1.0e300
@export("symmetric_mean_absolute_percentage_error")
fn symmetric_mean_absolute_percentage_error(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return INVALID_SMAPE
    let count=v[0]
    if count<1 or count>64 or n!=c_size_t(1+2*count):return INVALID_SMAPE
    for i in range(Int(count)*2):if v[1+i]< -1000000 or v[1+i]>1000000:return INVALID_SMAPE
    var total=0.0
    for i in range(Int(count)):
        let truth=Float64(v[1+i])/1000000.0;let prediction=Float64(v[1+Int(count)+i])/1000000.0
        var denominator=(abs(truth)+abs(prediction))/2.0
        if denominator==0.0:denominator=1e-15
        total+=abs(truth-prediction)/denominator
    return total/Float64(count)
