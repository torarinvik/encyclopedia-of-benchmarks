from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hinge_loss")
fn hinge_loss(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1.0e300
    let count=a[0];if count<1 or count>256 or n!=c_size_t(1+2*count):return -1.0e300
    var sum=0.0
    for i in range(Int(count)):
        let y=a[1+i];let ps=a[1+Int(count)+i]
        if (y!= -1 and y!=1) or ps< -1000000 or ps>1000000:return -1.0e300
        let loss=1.0-Float64(y)*Float64(ps)/1000000.0
        if loss>0.0:sum+=loss
    return sum/Float64(count)
