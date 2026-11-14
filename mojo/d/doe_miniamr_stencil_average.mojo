# Independent bounded stencil profile. miniAMR provenance, Sandia attribution,
# and LGPL-2.1-or-later notice are recorded in the benchmark package.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("doe_miniamr_stencil_average")
fn doe_miniamr_stencil_average(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 68 or length > 220: return -1.0e300
    let stencil = input[0]
    let x0 = input[1]
    let y0 = input[2]
    let z0 = input[3]
    if (stencil != 7 and stencil != 27) or (x0 != 2 and x0 != 4) or (y0 != 2 and y0 != 4) or (z0 != 2 and z0 != 4): return -1.0e300
    let nx = Int(x0)
    let ny = Int(y0)
    let nz = Int(z0)
    let cells = (nx + 2) * (ny + 2) * (nz + 2)
    if length != c_size_t(4 + cells): return -1.0e300
    for i in range(4, 4 + cells):
        if input[i] < -1000 or input[i] > 1000: return -1.0e300
    let si = (ny + 2) * (nz + 2)
    let sj = nz + 2
    var work = List[Float64](length=nx * ny * nz, fill=0.0)
    var count = 0
    for i in range(1, nx + 1):
        for j in range(1, ny + 1):
            for k in range(1, nz + 1):
                let base = 4 + i * si + j * sj + k
                if stencil == 7:
                    let sum = Float64(input[base - si]) + Float64(input[base - sj]) + Float64(input[base - 1]) + Float64(input[base]) + Float64(input[base + 1]) + Float64(input[base + sj]) + Float64(input[base + si])
                    work[count] = sum / 7.0
                else:
                    var slabs = List[Float64](length=3, fill=0.0)
                    for di in range(3):
                        var sum: Float64 = 0.0
                        for dj in range(3):
                            for dk in range(3):
                                sum += Float64(input[base + (di - 1) * si + (dj - 1) * sj + dk - 1])
                        slabs[di] = sum
                    work[count] = (slabs[0] + slabs[1] + slabs[2]) / 27.0
                count += 1
    var checksum: Float64 = 0.0
    for q in range(count): checksum += Float64(q + 1) * work[q] * work[q]
    return checksum
