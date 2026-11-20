from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MODULUS = 998244353
alias MAX_WORDS = 11
alias TABLE_COLUMNS = 9

fn stieltjes_mod(value: Int64) -> Int64:
    let reduced = value % MODULUS
    return if reduced < 0: reduced + MODULUS else: reduced

fn stieltjes_mul(left: Int64, right: Int64) -> Int64:
    return (left * right) % MODULUS

fn stieltjes_power(base_input: Int64, exponent_input: Int64) -> Int64:
    var base = base_input
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if exponent % 2 == 1:
            result = stieltjes_mul(result, base)
        base = stieltjes_mul(base, base)
        exponent //= 2
    return result

fn stieltjes_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("stieltjes_quotient_difference_transform")
fn stieltjes_quotient_difference_transform(
    input: UnsafePointer[Int64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < 3 or input_length > MAX_WORDS:
        return -1
    let count_value = input[0]
    if count_value < 2 or count_value > 9 or input_length != c_size_t(count_value + 1):
        return -1
    let count = Int(count_value)
    for i in range(count):
        let value = input[i + 1]
        if value <= 0 or value >= MODULUS:
            return -1

    var q = InlineArray[Int64, 45](fill=0)
    var e = InlineArray[Int64, 45](fill=0)
    for k in range(count - 1):
        q[TABLE_COLUMNS + k] = stieltjes_mul(input[k + 2], stieltjes_power(input[k + 1], MODULUS - 2))
    for j in range(1, 5):
        let last_e = count - 2 * j - 1
        if last_e < 0:
            break
        for k in range(last_e + 1):
            e[j * TABLE_COLUMNS + k] = stieltjes_mod(
                e[(j - 1) * TABLE_COLUMNS + k + 1] + q[j * TABLE_COLUMNS + k + 1] - q[j * TABLE_COLUMNS + k])
        let last_q = count - 2 * j - 2
        if last_q >= 0:
            for k in range(last_q + 1):
                let pivot = e[j * TABLE_COLUMNS + k]
                if pivot == 0:
                    return -1
                let product = stieltjes_mul(q[j * TABLE_COLUMNS + k + 1], e[j * TABLE_COLUMNS + k + 1])
                q[(j + 1) * TABLE_COLUMNS + k] = stieltjes_mul(product, stieltjes_power(pivot, MODULUS - 2))

    let required = 8 * (count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(required):
        return -2
    stieltjes_store_i64(output, 0, count_value)
    for index in range(1, count):
        let value = if index % 2 == 1: q[((index + 1) // 2) * TABLE_COLUMNS] else: e[(index // 2) * TABLE_COLUMNS]
        stieltjes_store_i64(output, 8 * index, value)
    return Int64(required)
