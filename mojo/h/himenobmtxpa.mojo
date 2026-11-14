from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("himenobmtxpa")
fn himenobmtxpa(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length != 4:
        return -1
    var dims = InlineArray[Int, 4](fill=0)
    for q in range(4):
        let value = input[q]
        if not isfinite(value):
            return -1
        if q < 3:
            if value < 2.0 or value > 6.0:
                return -1
        elif value < 1.0 or value > 4.0:
            return -1
        dims[q] = Int(value)
        if Float64(dims[q]) != value:
            return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 1:
        return -2
    let nx = dims[0]
    let ny = dims[1]
    let nz = dims[2]
    var field = InlineArray[Float32, 216](fill=0.0)
    var next = InlineArray[Float32, 216](fill=0.0)
    let denominator = Float32((nx - 1) * (nx - 1))
    let coefficient = Float32(1.0) / Float32(6.0)
    let omega = Float32(0.8)
    for i in range(nx):
        for j in range(ny):
            for k in range(nz):
                field[i * ny * nz + j * nz + k] = Float32(i * i) / denominator
    var residual: Float32 = 0.0
    for _ in range(dims[3]):
        residual = 0.0
        for i in range(1, nx - 1):
            for j in range(1, ny - 1):
                for k in range(1, nz - 1):
                    let q = i * ny * nz + j * nz + k
                    var neighbors = field[q + ny * nz] + field[q + nz]
                    neighbors += field[q + 1]
                    neighbors += field[q - ny * nz]
                    neighbors += field[q - nz]
                    neighbors += field[q - 1]
                    let delta = neighbors * coefficient - field[q]
                    residual += delta * delta
                    next[q] = field[q] + omega * delta
        for i in range(1, nx - 1):
            for j in range(1, ny - 1):
                for k in range(1, nz - 1):
                    let q = i * ny * nz + j * nz + k
                    field[q] = next[q]
    output[0] = Float64(residual)
    return 1
