from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import atan2, cos, isfinite, sin, sqrt
@export("geo_location")
fn geo_location(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=4:return -1
    for i in range(4):if not isfinite(v[i]):return -1
    if v[0]< -90.0 or v[0]>90.0 or v[2]< -90.0 or v[2]>90.0 or v[1]< -180.0 or v[1]>180.0 or v[3]< -180.0 or v[3]>180.0:return -1
    let factor=3.14159265358979323846/180.0;let lat1=v[0]*factor;let lon1=v[1]*factor;let lat2=v[2]*factor;let lon2=v[3]*factor
    let dlat=lat2-lat1;let dlon=lon2-lon1;let sl=sin(dlat/2.0);let so=sin(dlon/2.0)
    let hav=sl*sl+cos(lat1)*cos(lat2)*so*so
    if hav<0.0 or hav>1.0:return -1
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    out[0]=6371010.0*(2.0*atan2(sqrt(hav),sqrt(1.0-hav)));return 1
