from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_T = 8
const MAX_COMPONENT = 1_000_000
const MAX_OUTPUT_BYTES = 64

fn nearest_quotient(numerator: Int64, denominator: Int64) -> Int64:
    let sign: Int64 = if numerator < 0 then -1 else 1
    let magnitude = if numerator < 0 then -numerator else numerator
    var quotient = magnitude // denominator
    let remainder = magnitude % denominator
    if 2 * remainder >= denominator: quotient += 1
    return sign * quotient

fn write_u32(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: UInt32):
    output[offset] = UInt8(value & UInt32(255))
    output[offset + 1] = UInt8((value >> 8) & UInt32(255))
    output[offset + 2] = UInt8((value >> 16) & UInt32(255))
    output[offset + 3] = UInt8((value >> 24) & UInt32(255))

fn gaussian_gcd(ar_input: Int64, ai_input: Int64, br_input: Int64, bi_input: Int64) -> Tuple[Int64, Int64]:
    var ar = ar_input
    var ai = ai_input
    var br = br_input
    var bi = bi_input
    while br != 0 or bi != 0:
        let denominator = br * br + bi * bi
        let qr = nearest_quotient(ar * br + ai * bi, denominator)
        let qi = nearest_quotient(ai * br - ar * bi, denominator)
        let rr = ar - (qr * br - qi * bi)
        let ri = ai - (qr * bi + qi * br)
        ar = br
        ai = bi
        br = rr
        bi = ri
    if ar != 0 or ai != 0:
        for rotation in range(4):
            if ar > 0 and ai >= 0: break
            let old_real = ar
            ar = -ai
            ai = old_real
    return (ar, ai)

@export("gcd_of_gaussian_integers")
fn gcd_of_gaussian_integers(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(5) or length > c_size_t(1 + 4 * MAX_T): return -1
    let t_value = input[0]
    if t_value < 1 or t_value > MAX_T: return -1
    let t = Int(t_value)
    if Int(length) != 1 + 4 * t: return -1

    var values = InlineArray[Int64, MAX_T * 4](fill=0)
    for index in range(4 * t):
        let value = input[index + 1]
        if value < -MAX_COMPONENT or value > MAX_COMPONENT: return -1
        values[index] = value
    let required = 8 * t
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required) or required > MAX_OUTPUT_BYTES: return -2

    for test in range(t):
        let result = gaussian_gcd(values[4 * test], values[4 * test + 1],
            values[4 * test + 2], values[4 * test + 3])
        write_u32(output, 8 * test, UInt32(result[0]))
        write_u32(output, 8 * test + 4, UInt32(result[1]))
    return Int64(required)
