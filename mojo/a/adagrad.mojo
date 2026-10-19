from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn adagrad_sqrt(value: Float64) -> Float64:
    if value <= 0.0:
        return 0.0
    var root = value
    if root < 1.0:
        root = 1.0
    for _ in range(80):
        root = 0.5 * (root + value / root)
    return root

fn write_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8):
        output[pos + b] = UInt8((bits >> (8 * b)) & 255)

@export("adagrad")
fn adagrad(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 771:
        return -1
    let steps = input[0]
    let lr = input[1]
    let eps = input[2]
    if steps < 1 or steps > 256 or length != c_size_t(3 + 3 * steps) or lr < 1 or lr > 1000000000 or eps < 1 or eps > 10000000:
        return -1
    for step in range(steps):
        let base = 3 + 3 * step
        if input[base] < 0 or input[base] >= 16 or input[base + 1] < -1000000000000000 or input[base + 1] > 1000000000000000 or input[base + 2] < -1000000000000 or input[base + 2] > 1000000000000:
            return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * steps):
        return -2
    let learning_rate = Float64(lr) / 1000000000.0
    let epsilon = Float64(eps) / 1000000000.0
    var accumulated = List[Float64](length=16, fill=0.0)
    for step in range(steps):
        let base = 3 + 3 * step
        let id = Int(input[base])
        let parameter = Float64(input[base + 1]) / 1000000000.0
        let gradient = Float64(input[base + 2]) / 1000000000.0
        accumulated[id] += gradient * gradient
        let updated = parameter - learning_rate / (adagrad_sqrt(accumulated[id]) + epsilon) * gradient
        write_i64_le(output, Int(8 * step), Int64(updated * 1000000.0))
    return steps
