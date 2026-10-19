from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from math import abs
@export("smooth_l1_loss")
fn smooth_l1_loss(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>515:return -1.0e300
    let count=a[0];if count<1 or count>256 or n!=c_size_t(1+2*count):return -1.0e300
    var total=0.0
    for i in range(Int(count)):
        let x=Float64(a[i+1])/1000000.0;let y=Float64(a[Int(count)+i+1])/1000000.0
        if a[i+1]< -1000000 or a[i+1]>1000000 or a[Int(count)+i+1]< -1000000 or a[Int(count)+i+1]>1000000:return -1.0e300
        let d=abs(x-y);total+=0.5*d*d if d<1.0 else d-0.5
    return total/Float64(count)
