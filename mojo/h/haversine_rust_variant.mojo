from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sin, cos, sqrt, asin
@export("haversine_rust_variant")
fn haversine_rust_variant(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1.0e300
    if a[0]<-90000000 or a[0]>90000000 or a[2]<-90000000 or a[2]>90000000 or a[1]<-180000000 or a[1]>180000000 or a[3]<-180000000 or a[3]>180000000:return -1.0e300
    let pi=3.141592653589793;let lat1=Float64(a[0])/1.0e6*pi/180.0;let lat2=Float64(a[2])/1.0e6*pi/180.0
    let dlat=lat2-lat1;let dlon=Float64(a[3]-a[1])/1.0e6*pi/180.0
    var h=sin(dlat/2.0)*sin(dlat/2.0)+cos(lat1)*cos(lat2)*sin(dlon/2.0)*sin(dlon/2.0)
    h=max(0.0,min(1.0,h));return 2.0*sqrt(asin(h))*6371000.0
