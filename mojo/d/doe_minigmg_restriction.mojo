from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("doe_minigmg_restriction")
fn doe_minigmg_restriction(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 11 or length > 515: return -1.0e300
    let x0 = input[0]
    let y0 = input[1]
    let z0 = input[2]
    if x0 < 2 or x0 > 8 or x0 % 2 != 0 or y0 < 2 or y0 > 8 or y0 % 2 != 0 or z0 < 2 or z0 > 8 or z0 % 2 != 0: return -1.0e300
    let nx = Int(x0)
    let ny = Int(y0)
    let nz = Int(z0)
    let cells = nx * ny * nz
    if length != c_size_t(3 + cells): return -1.0e300
    for i in range(3, 3 + cells):
        if input[i] < -32768 or input[i] > 32767: return -1.0e300
    let plane = nx * ny
    var checksum: Float64 = 0.0
    var count = 0
    for k in range(nz // 2):
        for j in range(ny // 2):
            for i in range(nx // 2):
                let base = 3 + 2 * i + 2 * j * nx + 2 * k * plane
                var sum = Float64(input[base]) + Float64(input[base + 1])
                sum += Float64(input[base + nx]) + Float64(input[base + nx + 1])
                sum += Float64(input[base + plane]) + Float64(input[base + plane + 1])
                sum += Float64(input[base + plane + nx]) + Float64(input[base + plane + nx + 1])
                let restricted = sum * 0.125
                count += 1
                checksum += Float64(count) * restricted * restricted
    return checksum
