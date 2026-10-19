from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import atan2, cos, sin

comptime PI = 3.14159265358979323846264338327950288

@export("bearing")
fn bearing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4: return -1
    let lat1v = input[0]
    let lon1v = input[1]
    let lat2v = input[2]
    let lon2v = input[3]
    if lat1v < -90000000 or lat1v > 90000000 or lat2v < -90000000 or lat2v > 90000000 or
       lon1v < -180000000 or lon1v > 180000000 or lon2v < -180000000 or lon2v > 180000000 or
       (lat1v == lat2v and lon1v == lon2v): return -1
    let radians_per_microdegree = 0.000001 * (PI / 180.0)
    let lat1 = Float64(lat1v) * radians_per_microdegree
    let lon1 = Float64(lon1v) * radians_per_microdegree
    let lat2 = Float64(lat2v) * radians_per_microdegree
    let lon2 = Float64(lon2v) * radians_per_microdegree
    let delta = lon2 - lon1
    let east = sin(delta) * cos(lat2)
    let north = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(delta)
    var degrees = atan2(east, north) * (180.0 / PI)
    if degrees < 0.0: degrees += 360.0
    let result = Int64(degrees * 1000000.0 + 0.5)
    return 0 if result >= 360000000 else result
