# Bounded independent implementation; PolyBench provenance and license are in the package.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("fdtd_2d")
fn fdtd_2d(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 3: return -1
    let tv = input[0]
    let xv = input[1]
    let yv = input[2]
    if not isfinite(tv) or not isfinite(xv) or not isfinite(yv): return -1
    if tv < 0.0 or tv > 4.0 or xv < 1.0 or xv > 6.0 or yv < 1.0 or yv > 6.0: return -1
    let steps = Int(tv)
    let nx = Int(xv)
    let ny = Int(yv)
    if Float64(steps) != tv or Float64(nx) != xv or Float64(ny) != yv: return -1
    let cells = nx * ny
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(3 * cells): return -2
    var ex = List[Float64](length=cells, fill=0.0)
    var ey = List[Float64](length=cells, fill=0.0)
    var hz = List[Float64](length=cells, fill=0.0)
    for i in range(nx):
        for j in range(ny):
            let k = i * ny + j
            ex[k] = Float64(i * (j + 1)) / Float64(nx)
            ey[k] = Float64(i * (j + 2)) / Float64(ny)
            hz[k] = Float64(i * (j + 3)) / Float64(nx)
    for t in range(steps):
        for j in range(ny): ey[j] = Float64(t)
        for i in range(1, nx):
            for j in range(ny):
                let k = i * ny + j
                ey[k] = ey[k] - 0.5 * (hz[k] - hz[k - ny])
        for i in range(nx):
            for j in range(1, ny):
                let k = i * ny + j
                ex[k] = ex[k] - 0.5 * (hz[k] - hz[k - 1])
        for i in range(nx - 1):
            for j in range(ny - 1):
                let k = i * ny + j
                hz[k] = hz[k] - 0.7 * ((ex[k + 1] - ex[k]) + (ey[k + ny] - ey[k]))
    for i in range(cells):
        output[i] = ex[i]
        output[cells + i] = ey[i]
        output[2 * cells + i] = hz[i]
    return Int64(3 * cells)
