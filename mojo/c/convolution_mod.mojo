from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MODULUS = Int64(998244353)
alias MAX_LENGTH = 256
alias MAX_NTT_SIZE = 512
alias MAX_INPUT_LENGTH = 2 + 2 * MAX_LENGTH

fn power_mod(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = (result * base) % MODULUS
        base = (base * base) % MODULUS
        exponent >>= 1
    return result

fn transform(inout values: InlineArray[Int64, MAX_NTT_SIZE], n: Int, inverse: Bool):
    var j = 0
    for i in range(1, n):
        var bit = n >> 1
        while (j & bit) != 0:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            let temporary = values[i]
            values[i] = values[j]
            values[j] = temporary
    var stage = 2
    while stage <= n:
        var root = power_mod(3, (MODULUS - 1) // Int64(stage))
        if inverse:
            root = power_mod(root, MODULUS - 2)
        for start in range(0, n, stage):
            var factor: Int64 = 1
            for offset in range(stage // 2):
                let left = values[start + offset]
                let right = (values[start + offset + stage // 2] * factor) % MODULUS
                values[start + offset] = (left + right) % MODULUS
                values[start + offset + stage // 2] = (left - right + MODULUS) % MODULUS
                factor = (factor * root) % MODULUS
        stage *= 2
    if inverse:
        let scale = power_mod(Int64(n), MODULUS - 2)
        for i in range(n):
            values[i] = (values[i] * scale) % MODULUS

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("convolution_mod")
fn convolution_mod(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_LENGTH or m_value < 1 or m_value > MAX_LENGTH:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + n + m):
        return -1
    for i in range(n + m):
        let coefficient = input[2 + i]
        if coefficient < 0 or coefficient >= MODULUS:
            return -1

    let result_length = n + m - 1
    var transform_length = 1
    while transform_length < result_length:
        transform_length *= 2
    let output_bytes = 8 * result_length
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var a = InlineArray[Int64, MAX_NTT_SIZE]()
    var b = InlineArray[Int64, MAX_NTT_SIZE]()
    for i in range(n):
        a[i] = input[2 + i]
    for i in range(m):
        b[i] = input[2 + n + i]
    transform(a, transform_length, False)
    transform(b, transform_length, False)
    for i in range(transform_length):
        a[i] = (a[i] * b[i]) % MODULUS
    transform(a, transform_length, True)
    for i in range(result_length):
        store_i64_le(output, 8 * i, a[i])
    return Int64(output_bytes)
