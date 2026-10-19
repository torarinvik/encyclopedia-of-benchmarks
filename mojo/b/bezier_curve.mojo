from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn choose(n: Int, k_input: Int) -> UInt64:
    let k = min(k_input, n - k_input)
    var result: UInt64 = 1
    for index in range(1, k + 1): result = result * UInt64(n - k + index) // UInt64(index)
    return result

fn power(base: Float64, exponent: Int) -> Float64:
    var value: Float64 = 1.0
    for _ in range(exponent): value *= base
    return value

fn round_scaled(value: Float64) -> Int64:
    let scaled = value * 1_000_000.0
    return Int64(scaled + 0.5) if scaled >= 0.0 else Int64(scaled - 0.5)

fn append_word(mut bytes: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8):
        bytes.append(UInt8(bits & 255))
        bits >>= 8

@export("bezier_curve")
fn bezier_curve(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 34: return -1
    let count_value = input[0]
    let tq = input[1]
    if count_value < 1 or count_value > 16 or tq < 0 or tq > 1_000_000 or length != c_size_t(2 + 2 * count_value): return -1
    let count = Int(count_value)
    for i in range(2, Int(length)):
        if input[i] < -1_000_000 or input[i] > 1_000_000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 32: return -2
    let degree = count - 1
    let t = Float64(tq) / 1_000_000.0
    var x: Float64 = 0.0
    var y: Float64 = 0.0
    var dx: Float64 = 0.0
    var dy: Float64 = 0.0
    for i in range(count):
        let weight = Float64(choose(degree, i)) * power(1.0 - t, degree - i) * power(t, i)
        x += weight * Float64(input[2 + 2 * i])
        y += weight * Float64(input[3 + 2 * i])
    if degree > 0:
        for i in range(degree):
            let weight = Float64(degree) * Float64(choose(degree - 1, i)) * power(1.0 - t, degree - 1 - i) * power(t, i)
            dx += weight * Float64(input[4 + 2 * i] - input[2 + 2 * i])
            dy += weight * Float64(input[5 + 2 * i] - input[3 + 2 * i])
    var bytes = List[UInt8](capacity=32)
    append_word(bytes, round_scaled(x)); append_word(bytes, round_scaled(y))
    append_word(bytes, round_scaled(dx)); append_word(bytes, round_scaled(dy))
    for i in range(32): output[i] = bytes[i]
    return 32
