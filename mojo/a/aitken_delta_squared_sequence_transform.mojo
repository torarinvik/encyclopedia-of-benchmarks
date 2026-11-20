from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_TERMS = 64
const MAX_WORDS = 66
const VALUE_LIMIT = 1000000

fn aitken_gcd(left_value: UInt64, right_value: UInt64) -> UInt64:
    var left = left_value
    var right = right_value
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

fn aitken_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("aitken_delta_squared_sequence_transform")
fn aitken_delta_squared_sequence_transform(values: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_WORDS:
        return -1
    let n_value = values[0]
    if n_value < 2 or n_value > MAX_TERMS or length != c_size_t(n_value + 1):
        return -1
    let n = Int(n_value)
    for index in range(n):
        let value = values[index + 1]
        if value < -VALUE_LIMIT or value > VALUE_LIMIT:
            return -1
    let output_length = 16 * (n - 2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(output_length):
        return -2

    for index in range(n - 2):
        let first = values[index + 1]
        let middle = values[index + 2]
        let last = values[index + 3]
        var numerator = first * last - middle * middle
        var denominator = first - 2 * middle + last
        if denominator == 0:
            if first == middle and middle == last:
                numerator = first
                denominator = 1
            else:
                numerator = 0
        else:
            if denominator < 0:
                numerator = -numerator
                denominator = -denominator
            let magnitude = UInt64(-numerator) if numerator < 0 else UInt64(numerator)
            let divisor = aitken_gcd(magnitude, UInt64(denominator))
            numerator /= Int64(divisor)
            denominator /= Int64(divisor)
        let offset = index * 16
        aitken_store_i64(output, offset, numerator)
        aitken_store_i64(output, offset + 8, denominator)
    return Int64(output_length)
