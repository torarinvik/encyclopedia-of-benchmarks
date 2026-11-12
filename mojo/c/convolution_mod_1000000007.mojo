from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MODULUS = Int64(1_000_000_007)
alias P1 = Int64(998_244_353)
alias P2 = Int64(1_004_535_809)
alias P3 = Int64(469_762_049)
alias MAX_LENGTH = 64
alias NTT_SIZE = 128
alias MAX_RESULT = 2 * MAX_LENGTH - 1
alias MAX_INPUT_LENGTH = 2 + 2 * MAX_LENGTH

fn power_mod(base_value: Int64, exponent_value: Int64, modulus: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = (result * base) % modulus
        base = (base * base) % modulus
        exponent >>= 1
    return result

fn transform(inout values: InlineArray[Int64, NTT_SIZE], n: Int,
             modulus: Int64, inverse: Bool):
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
        var root = power_mod(3, (modulus - 1) // Int64(stage), modulus)
        if inverse:
            root = power_mod(root, modulus - 2, modulus)
        for start in range(0, n, stage):
            var factor: Int64 = 1
            for offset in range(stage // 2):
                let left = values[start + offset]
                let right = (values[start + offset + stage // 2] * factor) % modulus
                values[start + offset] = (left + right) % modulus
                values[start + offset + stage // 2] = (left - right + modulus) % modulus
                factor = (factor * root) % modulus
        stage *= 2
    if inverse:
        let scale = power_mod(Int64(n), modulus - 2, modulus)
        for i in range(n):
            values[i] = (values[i] * scale) % modulus

fn convolution_residues(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, m: Int,
    transform_length: Int, result_length: Int, modulus: Int64,
    inout result: InlineArray[Int64, MAX_RESULT]):
    var a = InlineArray[Int64, NTT_SIZE]()
    var b = InlineArray[Int64, NTT_SIZE]()
    for i in range(n): a[i] = input[2 + i] % modulus
    for i in range(m): b[i] = input[2 + n + i] % modulus
    transform(a, transform_length, modulus, False)
    transform(b, transform_length, modulus, False)
    for i in range(transform_length): a[i] = (a[i] * b[i]) % modulus
    transform(a, transform_length, modulus, True)
    for i in range(result_length): result[i] = a[i]

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("convolution_mod_1000000007")
fn convolution_mod_1000000007(
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
    if length != c_size_t(2 + n + m): return -1
    for i in range(n + m):
        let coefficient = input[2 + i]
        if coefficient < 0 or coefficient >= MODULUS: return -1
    let result_length = n + m - 1
    var transform_length = 1
    while transform_length < result_length: transform_length *= 2
    let output_bytes = 8 * result_length
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var r1 = InlineArray[Int64, MAX_RESULT]()
    var r2 = InlineArray[Int64, MAX_RESULT]()
    var r3 = InlineArray[Int64, MAX_RESULT]()
    convolution_residues(input, n, m, transform_length, result_length, P1, r1)
    convolution_residues(input, n, m, transform_length, result_length, P2, r2)
    convolution_residues(input, n, m, transform_length, result_length, P3, r3)
    let inv1 = power_mod(P1 % P2, P2 - 2, P2)
    let p12mod3 = (P1 % P3) * (P2 % P3) % P3
    let inv12 = power_mod(p12mod3, P3 - 2, P3)
    let p1mod = P1 % MODULUS
    let p12mod = p1mod * (P2 % MODULUS) % MODULUS
    for i in range(result_length):
        let t1 = ((r2[i] - r1[i] % P2 + P2) % P2) * inv1 % P2
        let x12 = (r1[i] % P3 + (P1 % P3) * (t1 % P3)) % P3
        let t2 = ((r3[i] - x12 + P3) % P3) * inv12 % P3
        let value = (r1[i] + p1mod * (t1 % MODULUS) + p12mod * (t2 % MODULUS)) % MODULUS
        store_i64_le(output, 8 * i, value)
    return Int64(output_bytes)
