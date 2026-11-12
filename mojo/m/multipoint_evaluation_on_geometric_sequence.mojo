from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime GEO_MODULUS: Int64 = 998244353
comptime GEO_MAX_N = 8
comptime GEO_MAX_M = 8
comptime GEO_NTT_SIZE = 32
comptime GEO_MAX_INPUT = 12

fn geo_mod_pow(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % GEO_MODULUS
        base = base * base % GEO_MODULUS
        exponent >>= 1
    return result

fn geo_ntt(inout values: InlineArray[Int64, GEO_NTT_SIZE], inverse: Bool):
    var j = 0
    for i in range(1, GEO_NTT_SIZE):
        var bit = GEO_NTT_SIZE // 2
        while (j & bit) != 0:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            let temp = values[i]
            values[i] = values[j]
            values[j] = temp
    var block = 2
    while block <= GEO_NTT_SIZE:
        var root = geo_mod_pow(3, (GEO_MODULUS - 1) // Int64(block))
        if inverse: root = geo_mod_pow(root, GEO_MODULUS - 2)
        let half = block // 2
        for start in range(0, GEO_NTT_SIZE, block):
            var factor: Int64 = 1
            for offset in range(half):
                let even = values[start + offset]
                let odd = values[start + offset + half] * factor % GEO_MODULUS
                values[start + offset] = (even + odd) % GEO_MODULUS
                values[start + offset + half] = (even - odd + GEO_MODULUS) % GEO_MODULUS
                factor = factor * root % GEO_MODULUS
        block *= 2
    if inverse:
        let scale = geo_mod_pow(Int64(GEO_NTT_SIZE), GEO_MODULUS - 2)
        for i in range(GEO_NTT_SIZE): values[i] = values[i] * scale % GEO_MODULUS

fn geo_evaluate(input: UnsafePointer[Int64, ImmutAnyOrigin], offset: Int,
                count: Int, x: Int64) -> Int64:
    var value: Int64 = 0
    for i in range(count, 0, -1): value = (value * x + input[offset + i - 1]) % GEO_MODULUS
    return value

fn geo_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("multipoint_evaluation_on_geometric_sequence")
fn multipoint_evaluation_on_geometric_sequence(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > GEO_MAX_INPUT: return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > GEO_MAX_N or m_value < 1 or m_value > GEO_MAX_M: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    let start = input[2]
    let ratio = input[3]
    if Int(length) != n + 4 or start < 0 or start >= GEO_MODULUS or ratio < 0 or ratio >= GEO_MODULUS: return -1
    for i in range(n):
        if input[4 + i] < 0 or input[4 + i] >= GEO_MODULUS: return -1
    let bytes = 8 * m
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes: return -2
    if start == 0:
        for i in range(m): geo_store_le(output, 8 * i, input[4])
        return Int64(bytes)
    if ratio == 0:
        geo_store_le(output, 0, geo_evaluate(input, 4, n, start))
        for i in range(1, m): geo_store_le(output, 8 * i, input[4])
        return Int64(bytes)

    let inverse_ratio = geo_mod_pow(ratio, GEO_MODULUS - 2)
    var left = InlineArray[Int64, GEO_NTT_SIZE]()
    var right = InlineArray[Int64, GEO_NTT_SIZE]()
    var start_power: Int64 = 1
    var inverse_chirp: Int64 = 1
    var inverse_ratio_power: Int64 = 1
    for degree in range(n):
        left[n - 1 - degree] = input[4 + degree] * start_power % GEO_MODULUS * inverse_chirp % GEO_MODULUS
        start_power = start_power * start % GEO_MODULUS
        inverse_chirp = inverse_chirp * inverse_ratio_power % GEO_MODULUS
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % GEO_MODULUS
    var chirp: Int64 = 1
    var ratio_power: Int64 = 1
    for index in range(n + m - 1):
        right[index] = chirp
        chirp = chirp * ratio_power % GEO_MODULUS
        ratio_power = ratio_power * ratio % GEO_MODULUS
    geo_ntt(left, false)
    geo_ntt(right, false)
    for i in range(GEO_NTT_SIZE): left[i] = left[i] * right[i] % GEO_MODULUS
    geo_ntt(left, true)
    inverse_chirp = 1
    inverse_ratio_power = 1
    for i in range(m):
        geo_store_le(output, 8 * i, left[n - 1 + i] * inverse_chirp % GEO_MODULUS)
        inverse_chirp = inverse_chirp * inverse_ratio_power % GEO_MODULUS
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % GEO_MODULUS
    return Int64(bytes)
