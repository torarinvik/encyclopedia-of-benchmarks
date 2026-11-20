from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_VERTICES = 16
const MAX_PARSEABLE_LENGTH = 34
const SCALE: Int64 = 1_000_000

fn rounded_micro(numerator_input: Int64, denominator_input: Int64) -> Int64:
    var numerator = numerator_input
    var denominator = denominator_input
    if denominator < 0:
        numerator = -numerator
        denominator = -denominator
    let sign: Int64 = -1 if numerator < 0 else 1
    let magnitude: UInt64 = UInt64(-numerator if numerator < 0 else numerator)
    let scaled = magnitude * UInt64(SCALE)
    let divisor = UInt64(denominator)
    var quotient = scaled // divisor
    if 2 * (scaled % divisor) >= divisor:
        quotient += 1
    return sign * Int64(quotient)

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("polygon_area_centroid")
fn polygon_area_centroid(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let count_value = input[0]
    if count_value < 3 or count_value > MAX_VERTICES:
        return -1
    let count = Int(count_value)
    if length != c_size_t(1 + 2 * count):
        return -1

    var xs = InlineArray[Int64, 16]()
    var ys = InlineArray[Int64, 16]()
    for i in range(count):
        let x = input[1 + 2 * i]
        let y = input[2 + 2 * i]
        if x < -50 or x > 50 or y < -50 or y > 50:
            return -1
        for j in range(i):
            if xs[j] == x and ys[j] == y:
                return -1
        xs[i] = x
        ys[i] = y

    var twice_area: Int64 = 0
    for i in range(count):
        let next = (i + 1) % count
        twice_area += xs[i] * ys[next] - xs[next] * ys[i]
    if twice_area == 0:
        return -1
    let orientation: Int64 = 1 if twice_area > 0 else -1
    for i in range(count):
        let next = (i + 1) % count
        for j in range(count):
            if j == i or j == next:
                continue
            let side = (xs[next] - xs[i]) * (ys[j] - ys[i]) - (ys[next] - ys[i]) * (xs[j] - xs[i])
            if side * orientation <= 0:
                return -1

    var numerator_x: Int64 = 0
    var numerator_y: Int64 = 0
    for i in range(count):
        let next = (i + 1) % count
        let cross = xs[i] * ys[next] - xs[next] * ys[i]
        numerator_x += (xs[i] + xs[next]) * cross
        numerator_y += (ys[i] + ys[next]) * cross
    let x_micro = rounded_micro(numerator_x, 3 * twice_area)
    let y_micro = rounded_micro(numerator_y, 3 * twice_area)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16:
        return -2
    store_i64_le(output, 0, x_micro)
    store_i64_le(output, 8, y_micro)
    return 16
