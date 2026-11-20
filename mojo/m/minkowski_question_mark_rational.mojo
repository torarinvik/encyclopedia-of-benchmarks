from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_DENOMINATOR = 1_000_000
alias MAX_CF_SUM = 60

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

fn cf_sum(numerator: Int64, denominator: Int64) -> Int64:
    var n = numerator
    var d = denominator
    var total: Int64 = 0
    while n != 0:
        let quotient = d // n
        if quotient > MAX_CF_SUM - total: return -1
        total += quotient
        let remainder = d % n
        d = n
        n = remainder
    return total

fn alternating_numerator(numerator: Int64, denominator: Int64,
                         total: Int64) -> Int64:
    var n = numerator
    var d = denominator
    var prefix: Int64 = 0
    var index: Int64 = 1
    var result: Int64 = 0
    while n != 0:
        let quotient = d // n
        prefix += quotient
        let shift = Int(total - prefix)
        let term = Int64(1) << shift
        if index % 2 == 1: result += term
        else: result -= term
        let remainder = d % n
        d = n
        n = remainder
        index += 1
    return result

@export("minkowski_question_mark_rational")
fn minkowski_question_mark_rational(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 3:
        return -1
    if length != 2: return -1
    let p = input[0]
    let q = input[1]
    if p < 0 or q < 1 or q > MAX_DENOMINATOR or p > q: return -1
    let total = cf_sum(p, q)
    if total < 0: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    let value = alternating_numerator(p, q, total)
    let exponent: Int64 = if total == 0: 0 else: total - 1
    store_i64_le(output, 0, value)
    store_i64_le(output, 8, exponent)
    return 16
