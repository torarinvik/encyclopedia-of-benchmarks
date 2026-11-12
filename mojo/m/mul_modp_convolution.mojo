from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MMP_MAX_P = 97
comptime MMP_MAX_INPUT = 196
comptime MMP_MOD: Int64 = 998244353

fn mmp_pow_mod(base_value: Int64, exponent_value: Int, modulus: Int) -> Int64:
    var base = base_value % Int64(modulus)
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = result * base % Int64(modulus)
        base = base * base % Int64(modulus)
        exponent >>= 1
    return result

fn mmp_is_prime(value: Int) -> Bool:
    if value < 2:
        return False
    var divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True

fn mmp_primitive_root(prime: Int) -> Int:
    let order = prime - 1
    var candidate = 1
    while candidate < prime:
        var good = True
        var factor = 2
        while factor <= order:
            if order % factor == 0 and mmp_is_prime(factor):
                if mmp_pow_mod(Int64(candidate), order / factor, prime) == 1:
                    good = False
            factor += 1
        if good:
            return candidate
        candidate += 1
    return 1

@export("mul_modp_convolution")
fn mul_modp_convolution(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > MMP_MAX_INPUT:
        return -1
    let count = Int(length)
    let p_value = input[0]
    if p_value < 2 or p_value > MMP_MAX_P:
        return -1
    let p = Int(p_value)
    if not mmp_is_prime(p) or count != 1 + 2 * p:
        return -1

    var a = InlineArray[Int64, 97]()
    var b = InlineArray[Int64, 97]()
    for i in range(p):
        let av = input[1 + i]
        let bv = input[1 + p + i]
        if av < 0 or av >= MMP_MOD or bv < 0 or bv >= MMP_MOD:
            return -1
        a[i] = av
        b[i] = bv

    let bytes = 8 * p
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2

    let order = p - 1
    let root = mmp_primitive_root(p)
    var residue_by_exp = InlineArray[Int32, 97]()
    var residue = 1
    for e in range(order):
        residue_by_exp[e] = Int32(residue)
        residue = residue * root % p

    var left = InlineArray[Int64, 97]()
    var right = InlineArray[Int64, 97]()
    var cyclic = InlineArray[Int64, 97]()
    var result = InlineArray[Int64, 97]()
    for e in range(order):
        let index = Int(residue_by_exp[e])
        left[e] = a[index]
        right[e] = b[index]
    for i in range(order):
        for j in range(order):
            let slot = (i + j) % order
            cyclic[slot] = (cyclic[slot] + left[i] * right[j] % MMP_MOD) % MMP_MOD

    var sum_a: Int64 = 0
    var sum_b_nonzero: Int64 = 0
    for i in range(p):
        sum_a = (sum_a + a[i]) % MMP_MOD
    for i in range(1, p):
        sum_b_nonzero = (sum_b_nonzero + b[i]) % MMP_MOD
    result[0] = (sum_a * b[0] % MMP_MOD + a[0] * sum_b_nonzero % MMP_MOD) % MMP_MOD
    for e in range(order):
        result[Int(residue_by_exp[e])] = cyclic[e]

    for i in range(p):
        let bits = bitcast[UInt64](result[i])
        for byte in range(8):
            output[i * 8 + byte] = UInt8((bits >> UInt(byte * 8)) & 255)
    return Int64(bytes)
