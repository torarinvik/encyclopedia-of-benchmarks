from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("hubble_parameter")
fn hubble_parameter(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=5 or a[0]< -2000 or a[0]>2000:return -1.0e300
    for i in range(1,4):if a[i]<0 or a[i]>1000000:return -1.0e300
    if a[1]+a[2]+a[3]>1000000 or a[4]<0 or a[4]>10000:return -1.0e300
    let h0=Float64(a[0])/10.0;let wr=Float64(a[1])/1000000.0;let wm=Float64(a[2])/1000000.0;let wde=Float64(a[3])/1000000.0;let z=Float64(a[4])/1000.0
    let curvature=1.0-(wm+wr+wde);let zp=z+1.0
    let e2=wr*(zp**4)+wm*(zp**3)+curvature*(zp**2)+wde
    return h0*sqrt(e2)
