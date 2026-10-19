from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cross_correlation")
fn cross_correlation(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 66: return -1
    let nx = values[0]
    let ny = values[1]
    if nx < 1 or nx > 32 or ny < 1 or ny > 32 or length != nx + ny + 2: return -1
    for i in range(nx + ny):
        if values[i + 2] < -1000000 or values[i + 2] > 1000000: return -1
    let count = nx + ny - 1
    let bytes = count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    var stage = InlineArray[Int64, 63](0)
    var y_start = ny
    for index in range(count):
        if index < ny: y_start -= 1
        let k_min = index - (ny - 1) if index >= ny - 1 else 0
        let k_max = index if index < nx else nx - 1
        var total: Int64 = 0
        for k in range(k_min, k_max + 1):
            let yi = y_start + (k - k_min)
            total += values[k + 2] * values[nx + yi + 2]
        stage[index] = total
    for i in range(count):
        let bits = UInt64(stage[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
