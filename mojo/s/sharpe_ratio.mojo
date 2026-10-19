from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("sharpe_ratio")
fn sharpe_ratio(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>66:return -1.0e300
    let count=a[0];if count<2 or count>64 or n!=c_size_t(count+2):return -1.0e300
    var mean=0.0;var first:Int64=0
    for i in range(Int(count)):
        let v=a[i+1];if v< -200000 or v>200000:return -1.0e300
        if i==0:first=v
        elif v!=first:pass
        mean+=Float64(v)/1e6
    if mean==Float64(first)*Float64(count)/1e6:return -1.0e300
    let rf=a[Int(count)+1];if rf< -100000 or rf>100000:return -1.0e300
    mean/=Float64(count);var sum=0.0
    for i in range(Int(count)):let d=Float64(a[i+1])/1e6-mean;sum+=d*d
    let sd=(sum/Float64(count-1))**0.5
    if sd==0:return -1.0e300
    return (mean-Float64(rf)/1e6)/sd
