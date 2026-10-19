from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("weighted_average")
fn weighted_average(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>129:return -1.0e300
    let count=a[0]
    if count<1 or count>64 or n!=c_size_t(1+2*count):return -1.0e300
    var ws:Int64=0;var total:Int64=0
    for i in range(Int(count)):
        let v=a[i+1];let w=a[i+1+Int(count)]
        if v< -1000000 or v>1000000 or w< -1000000 or w>1000000:return -1.0e300
        ws+=v*w;total+=w
    if total==0:return -1.0e300
    return Float64(ws)/Float64(total)
