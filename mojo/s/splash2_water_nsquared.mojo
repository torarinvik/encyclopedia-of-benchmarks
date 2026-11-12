from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_PARSEABLE = 260
comptime MAX_WORDS = 194

fn swn_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

fn swn_trunc_div(numerator: Int64, denominator: Int64) -> Int64:
    if numerator < 0:
        return -((-numerator) / denominator)
    return numerator / denominator

@export("splash2_water_nsquared")
fn splash2_water_nsquared(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_PARSEABLE):
        return -1
    let n_value = input[0]
    let grid = input[1]
    let radius = input[2]
    if n_value < 0 or n_value > MAX_N or grid < 1 or grid > 8 or radius < 1 or radius > 4:
        return -1
    let n = Int(n_value)
    if length != c_size_t(3 + 4 * n):
        return -1
    let side = grid * radius
    let radius2 = radius * radius
    var x = InlineArray[Int64, MAX_N](fill=0)
    var y = InlineArray[Int64, MAX_N](fill=0)
    var z = InlineArray[Int64, MAX_N](fill=0)
    var charge = InlineArray[Int64, MAX_N](fill=0)
    for i in range(n):
        let at = 3 + 4 * i
        x[i] = input[at]
        y[i] = input[at + 1]
        z[i] = input[at + 2]
        charge[i] = input[at + 3]
        if x[i] < 0 or x[i] >= side or y[i] < 0 or y[i] >= side or z[i] < 0 or z[i] >= side or charge[i] < -4 or charge[i] > 4:
            return -1
    var force = InlineArray[Int64, 3 * MAX_N](fill=0)
    var energy: Int64 = 0
    var pairs: Int64 = 0
    for i in range(n):
        for j in range(i + 1, n):
            let dx = x[j] - x[i]
            let dy = y[j] - y[i]
            let dz = z[j] - z[i]
            let r2 = dx * dx + dy * dy + dz * dz
            if r2 >= radius2:
                continue
            let product = charge[i] * charge[j]
            energy += swn_trunc_div(product * (radius2 - r2) * 1000000, (1 + r2) * (1 + radius2))
            let denominator = (1 + r2) * (1 + r2)
            let fx = swn_trunc_div(-2 * product * dx * 1000000, denominator)
            let fy = swn_trunc_div(-2 * product * dy * 1000000, denominator)
            let fz = swn_trunc_div(-2 * product * dz * 1000000, denominator)
            force[3 * i] += fx
            force[3 * i + 1] += fy
            force[3 * i + 2] += fz
            force[3 * j] -= fx
            force[3 * j + 1] -= fy
            force[3 * j + 2] -= fz
            pairs += 1
    let words = 3 * n + 2
    let output_bytes = words * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for i in range(3 * n):
        swn_store(output, 8 * i, force[i])
    swn_store(output, 24 * n, energy)
    swn_store(output, 24 * n + 8, pairs)
    Int64(output_bytes)
