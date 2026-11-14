# Parboil seven-point Laplacian with fixed boundaries and Float32 steps.
from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("parboil_stencil_laplacian")
fn parboil_stencil_laplacian(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 4 or length > 129: return -1
    for i in range(4):
        if not isfinite(input[i]): return -1
    let nxv = input[0]
    let nyv = input[1]
    let nzv = input[2]
    let sv = input[3]
    if nxv < 3.0 or nxv > 5.0 or nyv < 3.0 or nyv > 5.0 or nzv < 3.0 or nzv > 5.0 or sv < 1.0 or sv > 4.0: return -1
    let nx = Int(nxv)
    let ny = Int(nyv)
    let nz = Int(nzv)
    let steps = Int(sv)
    if Float64(nx) != nxv or Float64(ny) != nyv or Float64(nz) != nzv or Float64(steps) != sv: return -1
    let cells = nx*ny*nz
    if length != c_size_t(4+cells): return -1
    var a = List[Float32](capacity=cells)
    var b = List[Float32](capacity=cells)
    for i in range(cells):
        let value = input[4+i]
        if not isfinite(value) or value < -8.0 or value > 8.0: return -1
        a.append(Float32(value)); b.append(Float32(value))
    let c0 = Float32(1.0)/Float32(6.0)
    let c1 = c0/Float32(6.0)
    for _ in range(steps):
        for x in range(1,nx-1):
            for y in range(1,ny-1):
                for z in range(1,nz-1):
                    let index = x+nx*(y+ny*z)
                    var sum = a[index+nx*ny]+a[index-nx*ny]
                    sum += a[index+nx]
                    sum += a[index-nx]
                    sum += a[index+1]
                    sum += a[index-1]
                    let neighbor_term = sum*c1
                    let center_term = a[index]*c0
                    b[index] = neighbor_term-center_term
        for i in range(cells):
            let previous = a[i]
            a[i] = b[i]
            b[i] = previous
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(cells): return -2
    for i in range(cells): output[i] = Float64(a[i])
    return Int64(cells)
