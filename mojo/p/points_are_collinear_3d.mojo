from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("points_are_collinear_3d")
fn points_are_collinear_3d(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 9: return -1
    for i in range(9):
        if v[i] < -10000 or v[i] > 10000: return -1
    let abx = v[3] - v[0]; let aby = v[4] - v[1]; let abz = v[5] - v[2]
    let acx = v[6] - v[0]; let acy = v[7] - v[1]; let acz = v[8] - v[2]
    if aby * acz - abz * acy == 0 and abz * acx - abx * acz == 0 and abx * acy - aby * acx == 0: return 1
    return 0
