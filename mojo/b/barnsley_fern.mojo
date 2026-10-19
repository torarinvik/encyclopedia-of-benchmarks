from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_ITERATIONS = 4096
comptime Q12_OFFSET = 10000000000
comptime Q6_DIVISOR = 1000000

fn round_div_even(numerator: Int64, denominator: Int64) -> Int64:
    let negative = numerator < 0
    let magnitude = abs(numerator)
    var quotient = magnitude / denominator
    let remainder = magnitude % denominator
    if remainder * 2 > denominator or (remainder * 2 == denominator and (quotient & 1) != 0):
        quotient += 1
    return -quotient if negative else quotient

fn append_i64_le(mut out: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8):
        out.append(UInt8(bits & 255))
        bits >>= 8

@export("barnsley_fern")
fn barnsley_fern(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0:
        return -1
    let count_value = input[0]
    if count_value < 1 or count_value > MAX_ITERATIONS or length != c_size_t(count_value):
        return -1
    let count = Int(count_value)
    for step in range(1, count):
        if input[step] < 0 or input[step] >= 10000:
            return -1
    let required = count * 16
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    var staged = List[UInt8](capacity=required)
    var x: Int64 = 0
    var y: Int64 = 0
    append_i64_le(staged, 0)
    append_i64_le(staged, 0)
    for step in range(1, count):
        let sample = input[step]
        var a: Int64 = 0
        var b: Int64 = 0
        var c: Int64 = 0
        var d: Int64 = 16
        var f: Int64 = 0
        if sample >= 100 and sample < 8600:
            a = 85; b = 4; c = -4; d = 85; f = 160
        elif sample >= 8600 and sample < 9300:
            a = 20; b = -26; c = 23; d = 22; f = 160
        elif sample >= 9300:
            a = -15; b = 28; c = 26; d = 24; f = 44
        let next_x = round_div_even(a * x + b * y, 100)
        let next_y = round_div_even(c * x + d * y, 100) + f * Q12_OFFSET
        x = next_x
        y = next_y
        append_i64_le(staged, round_div_even(x, Q6_DIVISOR))
        append_i64_le(staged, round_div_even(y, Q6_DIVISOR))
    for i in range(required):
        output[i] = staged[i]
    return Int64(required)
