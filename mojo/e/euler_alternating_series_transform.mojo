from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_TERMS = 16
const MAX_WORDS = 18
const VALUE_LIMIT = 1000000
const OUTPUT_BYTES = 16

fn euler_gcd(left_value: UInt64, right_value: UInt64) -> UInt64:
    var left = left_value
    var right = right_value
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

fn euler_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("euler_alternating_series_transform")
fn euler_alternating_series_transform(values: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_WORDS:
        return -1
    let n_value = values[0]
    if n_value < 1 or n_value > MAX_TERMS or length != c_size_t(n_value + 1):
        return -1
    let n = Int(n_value)
    for index in range(n):
        let value = values[index + 1]
        if value < -VALUE_LIMIT or value > VALUE_LIMIT:
            return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(OUTPUT_BYTES):
        return -2

    var numerator: Int64 = 0
    for order in range(n):
        var difference: Int64 = 0
        var coefficient: Int64 = 1
        for index in range(order + 1):
            let term = values[order - index + 1]
            if index % 2 == 0:
                difference += coefficient * term
            else:
                difference -= coefficient * term
            if index < order:
                coefficient = coefficient * Int64(order - index) / Int64(index + 1)
        let weight = Int64(1) << UInt(n - order - 1)
        let weighted = difference * weight
        if order % 2 == 0:
            numerator += weighted
        else:
            numerator -= weighted

    var denominator = Int64(1) << UInt(n)
    let magnitude = UInt64(-numerator) if numerator < 0 else UInt64(numerator)
    let divisor = euler_gcd(magnitude, UInt64(denominator))
    numerator /= Int64(divisor)
    denominator /= Int64(divisor)
    euler_store_i64(output, 0, numerator)
    euler_store_i64(output, 8, denominator)
    return Int64(OUTPUT_BYTES)
