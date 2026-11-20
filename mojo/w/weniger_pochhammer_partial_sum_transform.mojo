from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MIN_WORDS = 7
alias MAX_WORDS = 17
alias OUTPUT_BYTES = 16

fn weniger_gcd(a_input: Int64, b_input: Int64) -> Int64:
    var a = a_input
    var b = b_input
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

fn weniger_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("weniger_pochhammer_partial_sum_transform")
fn weniger_pochhammer_partial_sum_transform(
    input: UnsafePointer[Int64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < MIN_WORDS or input_length > MAX_WORDS:
        return -1
    let n0 = input[0]
    let k0 = input[1]
    if n0 < 0 or n0 > 8 or k0 < 3 or k0 > 4:
        return -1
    let n = Int(n0)
    let k = Int(k0)
    if input_length != c_size_t(n + k + 4):
        return -1
    let term_count = n + k + 2
    for i in range(term_count):
        let value = input[i + 2]
        if value == 0 or value < -3 or value > 3:
            return -1

    var product: Int64 = 1
    for r in range(k + 1):
        product *= input[n + r + 3]
    var numerator: Int64 = 0
    var denominator: Int64 = 0
    for j in range(k + 1):
        var choose: Int64 = 1
        for r in range(1, j + 1):
            choose = choose * Int64(k - r + 1) // Int64(r)
        var rising: Int64 = 1
        for offset in range(k - 1):
            rising *= Int64(n + j + 1 + offset)
        let term = input[n + j + 3]
        var weight = choose * rising * (product // term)
        if j % 2 == 1:
            weight = -weight
        var partial: Int64 = 0
        for index in range(n + j + 1):
            partial += input[index + 2]
        numerator += weight * partial
        denominator += weight
    if denominator == 0:
        return -1
    if denominator < 0:
        numerator = -numerator
        denominator = -denominator
    let magnitude = if numerator < 0: -numerator else: numerator
    let divisor = weniger_gcd(magnitude, denominator)
    numerator //= divisor
    denominator //= divisor
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < OUTPUT_BYTES:
        return -2
    weniger_store_i64(output, 0, numerator)
    weniger_store_i64(output, 8, denominator)
    return OUTPUT_BYTES
