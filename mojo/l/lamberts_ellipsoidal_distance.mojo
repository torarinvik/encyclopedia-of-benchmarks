from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import asin, atan, cos, pow, sin, sqrt, tan

comptime PI = 3.14159265358979323846264338327950288

@export("lamberts_ellipsoidal_distance")
fn lamberts_ellipsoidal_distance(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 4: return -1.0e300
    if v[0] < -90000000 or v[0] > 90000000 or v[2] < -90000000 or v[2] > 90000000: return -1.0e300
    if v[1] < -180000000 or v[1] > 180000000 or v[3] < -180000000 or v[3] > 180000000: return -1.0e300
    if v[0] == v[2] and v[1] == v[3]: return -1.0e300
    let lat1 = Float64(v[0]) / 1.0e6; let lon1 = Float64(v[1]) / 1.0e6
    let lat2 = Float64(v[2]) / 1.0e6; let lon2 = Float64(v[3]) / 1.0e6
    let p1 = lat1 * PI / 180.0; let p2 = lat2 * PI / 180.0
    let l1 = lon1 * PI / 180.0; let l2 = lon2 * PI / 180.0
    let h = sqrt(pow(sin((p2-p1)/2.0), 2.0) + cos(p1)*cos(p2)*pow(sin((l2-l1)/2.0), 2.0))
    if h == 0.0: return -1.0e300
    let sigma = 2.0 * asin(h); let f = (6378137.0 - 6356752.314245) / 6378137.0
    let b1 = atan((1.0-f)*tan(lat1*PI/180.0)); let b2 = atan((1.0-f)*tan(lat2*PI/180.0))
    let p = (b1+b2)/2.0; let q = (b2-b1)/2.0
    let x = (sigma-sin(sigma))*((pow(sin(p),2.0)*pow(cos(q),2.0))/pow(cos(sigma/2.0),2.0))
    let y = (sigma+sin(sigma))*((pow(cos(p),2.0)*pow(sin(q),2.0))/pow(sin(sigma/2.0),2.0))
    return 6378137.0*(sigma-(f/2.0)*(x+y))
