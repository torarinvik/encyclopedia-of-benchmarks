from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_LENGTH = 64
alias MAX_NTT_SIZE = 128
alias MAX_INPUT_LENGTH = 2 + 2 * MAX_LENGTH + 1
alias MAX_RESULT_LENGTH = 2 * MAX_LENGTH - 1
alias P0 = Int64(998244353)
alias P1 = Int64(985661441)
alias P2 = Int64(943718401)
alias P3 = Int64(935329793)
alias P4 = Int64(918552577)

fn power_mod(base_value: Int64, exponent_value: Int64, modulus: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = (result * base) % modulus
        base = (base * base) % modulus
        exponent >>= 1
    return result

fn transform(inout values: InlineArray[Int64, MAX_NTT_SIZE], n: Int,
             modulus: Int64, primitive_root: Int64, inverse: Bool):
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
        var root = power_mod(primitive_root, (modulus - 1) // Int64(stage), modulus)
        if inverse: root = power_mod(root, modulus - 2, modulus)
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
        for i in range(n): values[i] = (values[i] * scale) % modulus

fn convolution_residues(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, m: Int,
    transform_length: Int, modulus: Int64, primitive_root: Int64,
    inout result: InlineArray[Int64, MAX_RESULT_LENGTH]):
    var a = InlineArray[Int64, MAX_NTT_SIZE]()
    var b = InlineArray[Int64, MAX_NTT_SIZE]()
    for i in range(n): a[i] = Int64(bitcast[UInt64](input[2 + i]) % UInt64(modulus))
    for i in range(m): b[i] = Int64(bitcast[UInt64](input[2 + n + i]) % UInt64(modulus))
    transform(a, transform_length, modulus, primitive_root, False)
    transform(b, transform_length, modulus, primitive_root, False)
    for i in range(transform_length): a[i] = (a[i] * b[i]) % modulus
    transform(a, transform_length, modulus, primitive_root, True)
    for i in range(n + m - 1): result[i] = a[i]

fn positive_delta(value: Int64, partial: Int64, modulus: Int64) -> Int64:
    let delta = value - partial
    if delta < 0: return delta + modulus
    return delta

fn store_u64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: UInt64):
    for byte in range(8): output[offset + byte] = UInt8((value >> UInt(8 * byte)) & 255)

@export("convolution_mod_2_64")
fn convolution_mod_2_64(
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
    let result_length = n + m - 1
    var transform_length = 1
    while transform_length < result_length: transform_length *= 2
    let output_bytes = 8 * result_length
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var r0 = InlineArray[Int64, MAX_RESULT_LENGTH]()
    var r1 = InlineArray[Int64, MAX_RESULT_LENGTH]()
    var r2 = InlineArray[Int64, MAX_RESULT_LENGTH]()
    var r3 = InlineArray[Int64, MAX_RESULT_LENGTH]()
    var r4 = InlineArray[Int64, MAX_RESULT_LENGTH]()
    convolution_residues(input, n, m, transform_length, P0, 3, r0)
    convolution_residues(input, n, m, transform_length, P1, 3, r1)
    convolution_residues(input, n, m, transform_length, P2, 7, r2)
    convolution_residues(input, n, m, transform_length, P3, 3, r3)
    convolution_residues(input, n, m, transform_length, P4, 5, r4)

    let p01_p2 = (P0 % P2) * (P1 % P2) % P2
    let p01_p3 = (P0 % P3) * (P1 % P3) % P3
    let p01_p4 = (P0 % P4) * (P1 % P4) % P4
    let p012_p3 = p01_p3 * (P2 % P3) % P3
    let p012_p4 = p01_p4 * (P2 % P4) % P4
    let p0123_p4 = p012_p4 * (P3 % P4) % P4
    let inv0_p1 = power_mod(P0 % P1, P1 - 2, P1)
    let inv01_p2 = power_mod(p01_p2, P2 - 2, P2)
    let inv012_p3 = power_mod(p012_p3, P3 - 2, P3)
    let inv0123_p4 = power_mod(p0123_p4, P4 - 2, P4)
    for i in range(result_length):
        let t0 = r0[i]
        let t1 = (positive_delta(r1[i], t0 % P1, P1) * inv0_p1) % P1
        let x01_p2 = (r0[i] % P2 + (P0 % P2) * t1) % P2
        let t2 = (positive_delta(r2[i], x01_p2, P2) * inv01_p2) % P2
        let x012_p3 = (r0[i] % P3 + (P0 % P3) * t1 + p01_p3 * t2) % P3
        let t3 = (positive_delta(r3[i], x012_p3, P3) * inv012_p3) % P3
        let x0123_p4 = (r0[i] % P4 + (P0 % P4) * t1 + p01_p4 * t2 + p012_p4 * t3) % P4
        let t4 = (positive_delta(r4[i], x0123_p4, P4) * inv0123_p4) % P4
        let value = UInt64(t0) + UInt64(P0) * UInt64(t1)
            + UInt64(P0) * UInt64(P1) * UInt64(t2)
            + UInt64(P0) * UInt64(P1) * UInt64(P2) * UInt64(t3)
            + UInt64(P0) * UInt64(P1) * UInt64(P2) * UInt64(P3) * UInt64(t4)
        store_u64_le(output, 8 * i, value)
    return Int64(output_bytes)
