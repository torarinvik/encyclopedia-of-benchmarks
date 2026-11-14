# Independent bounded stencil profile; see the package rights note.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("asci_purple_smg2000_residual")
fn asci_purple_smg2000_residual(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 19 or length > 253: return -1
    for i in range(3):
        let v = input[i]
        if not isfinite(v) or v < 2.0 or v > 5.0 or Float64(Int(v)) != v: return -1
    let nx = Int(input[0])
    let ny = Int(input[1])
    let nz = Int(input[2])
    let cells = nx * ny * nz
    if length != c_size_t(3 + 2 * cells): return -1
    var field = List[Int64](capacity=2*cells)
    for i in range(2*cells):
        let v = input[3+i]
        if not isfinite(v) or v < -1000.0 or v > 1000.0 or Float64(Int64(v)) != v: return -1
        field.append(Int64(v))
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(cells): return -2
    let si = ny*nz
    let sj = nz
    for i in range(nx):
        for j in range(ny):
            for k in range(nz):
                let q = i*si + j*sj + k
                var ax = 222 * field[q]
                if i > 0: ax -= field[q-si]
                if i+1 < nx: ax -= field[q+si]
                if j > 0: ax -= 10 * field[q-sj]
                if j+1 < ny: ax -= 10 * field[q+sj]
                if k > 0: ax -= 100 * field[q-1]
                if k+1 < nz: ax -= 100 * field[q+1]
                output[q] = Float64(10 * field[cells+q] - ax) / 10.0
    return Int64(cells)
