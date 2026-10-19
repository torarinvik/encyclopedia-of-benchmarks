from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("trapezoidal_integration")
fn trapezoidal_integration(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1.0e300
    let sm=a[0];let em=a[1];let steps=a[2];let fid=a[3]
    if sm< -1000000 or sm>1000000 or em< -1000000 or em>1000000 or steps<1 or steps>10000 or fid<0 or fid>1:return -1.0e300
    let start=Float64(sm)/1000000.0;let end=Float64(em)/1000000.0;let delta=(end-start)/Float64(steps);var total:Float64=0.0
    for index in range(Int(steps)):
        let left=start+delta*Float64(index);let right=left+delta
        let fl=left*left if fid==0 else left*left*left
        let fr=right*right if fid==0 else right*right*right
        let midpoint=(fl+fr)*0.5;total+=midpoint*delta
    return total
