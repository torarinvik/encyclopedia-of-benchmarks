from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import atan2, cos, sin, sqrt
@export("geofence")
fn geofence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=5:return -1
    if v[0]< -90000000 or v[0]>90000000 or v[2]< -90000000 or v[2]>90000000 or v[1]< -180000000 or v[1]>180000000 or v[3]< -180000000 or v[3]>180000000 or v[4]< -1000000 or v[4]>30000000000:return -1
    let f=3.14159265358979323846/180000000.0;let lat1=Float64(v[0])*f;let lon1=Float64(v[1])*f;let lat2=Float64(v[2])*f;let lon2=Float64(v[3])*f
    let sl=sin((lat2-lat1)/2.0);let so=sin((lon2-lon1)/2.0);var hav=sl*sl+cos(lat1)*cos(lat2)*so*so
    if hav<0.0:hav=0.0
    if hav>1.0:hav=1.0
    let dist=6371010.0*(2.0*atan2(sqrt(hav),sqrt(1.0-hav)))
    return 1 if dist<=Float64(v[4])/1000.0 else 0
