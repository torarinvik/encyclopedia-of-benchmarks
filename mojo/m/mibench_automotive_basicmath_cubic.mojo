# Independently written bounded cubic solver; see the package attribution.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import acos, cos, isfinite, pow, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("mibench_automotive_basicmath_cubic")
fn mibench_automotive_basicmath_cubic(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                                     output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 4: return -1
    for i in range(4):
        if not isfinite(input[i]) or input[i] < -100.0 or input[i] > 100.0: return -1
    if input[0] > -1.0 and input[0] < 1.0: return -1
    let a = input[1]/input[0]; let b = input[2]/input[0]; let c = input[3]/input[0]
    let q = (a*a-3.0*b)/9.0
    let r = (2.0*a*a*a-9.0*a*b+27.0*c)/54.0
    let discriminant = r*r-q*q*q
    if discriminant == 0.0: return -1
    var roots = InlineArray[Float64, 3](fill=0.0)
    var count = 1
    if discriminant < 0.0:
        let theta = acos(r/sqrt(q*q*q))
        let pi = acos(-1.0)
        let scale = -2.0*sqrt(q)
        roots[0] = scale*cos(theta/3.0)-a/3.0
        roots[1] = scale*cos((theta+2.0*pi)/3.0)-a/3.0
        roots[2] = scale*cos((theta+4.0*pi)/3.0)-a/3.0
        count = 3
    else:
        var absolute_r = r
        if absolute_r < 0.0: absolute_r = -absolute_r
        var root = pow(sqrt(discriminant)+absolute_r, 1.0/3.0)
        root += q/root
        if r >= 0.0: root = -root
        roots[0] = root-a/3.0
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(count): return -2
    for i in range(count): output[i] = roots[i]
    return Int64(count)
