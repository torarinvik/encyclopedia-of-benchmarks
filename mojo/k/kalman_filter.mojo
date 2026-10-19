from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import isfinite
@export("kalman_filter")
fn kalman_filter(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<5 or n>64:return -1
    for i in range(Int(n)):if not isfinite(a[i]) or Float64(Int64(a[i]))!=a[i]:return -1
    let steps=a[4]
    if steps<1 or steps>12 or n!=c_size_t(5+Int(steps)) or a[0]< -1000000000.0 or a[0]>1000000000.0 or a[1]<0 or a[1]>1000000000000.0 or a[2]<0 or a[2]>1000000000000.0 or a[3]<1 or a[3]>1000000000000.0:return -1
    for i in range(Int(steps)):if a[5+i]< -1000000000.0 or a[5+i]>1000000000.0:return -1
    let required=3*Int(steps)
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(required):return -2
    var estimate=a[0]/1000000.0;var covariance=a[1]/1000000.0;let q=a[2]/1000000.0;let r=a[3]/1000000.0
    for i in range(Int(steps)):
        let measurement=a[5+i]/1000000.0;covariance+=q;let innovation=covariance+r;let gain=covariance/innovation
        estimate+=gain*(measurement-estimate);covariance=covariance*r/innovation
        o[3*i]=estimate;o[3*i+1]=covariance;o[3*i+2]=gain
    return Int64(required)
