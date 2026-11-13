from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime BCP_MAX_QUERIES = 32
comptime BCP_MAX_N = 128
comptime BCP_MAX_PARSEABLE = 68
comptime BCP_MAX_MODULUS = 1_000_000_000

fn bcp_is_prime(value: Int64) -> Bool:
    if value < 2: return False
    var divisor: Int64 = 2
    while divisor <= value // divisor:
        if value % divisor == 0: return False
        divisor += 1
    True

fn bcp_pow_mod(base_value: Int64, exponent_value: Int64, modulus: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % modulus
        base = base * base % modulus
        exponent >>= 1
    result

@export("binomial_coefficient_prime_power")
fn binomial_coefficient_prime_power(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(BCP_MAX_PARSEABLE): return -1
    let p = input[0]
    let e = input[1]
    let q_arg = input[2]
    if p < 2 or p > 31 or not bcp_is_prime(p) or e < 1 or e > 8 or q_arg < 0 or q_arg > BCP_MAX_QUERIES: return -1
    var modulus: Int64 = 1
    for _ in range(Int(e)):
        modulus *= p
        if modulus > BCP_MAX_MODULUS: return -1
    let q = Int(q_arg)
    if Int(length) != 3 + 2 * q: return -1
    for i in range(q):
        let n = input[3 + 2 * i]
        let k = input[4 + 2 * i]
        if n < 0 or n > BCP_MAX_N or k < 0 or k > n: return -1
    if q == 0: return 0
    let required = 4 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < required: return -2

    var unit_prefix = InlineArray[Int64, BCP_MAX_N + 1](fill=0)
    var p_free_factorial = InlineArray[Int64, BCP_MAX_N + 1](fill=0)
    var valuation = InlineArray[UInt16, BCP_MAX_N + 1](fill=0)
    var residues = InlineArray[UInt32, BCP_MAX_QUERIES](fill=0)
    unit_prefix[0] = 1
    p_free_factorial[0] = 1
    for n in range(1, BCP_MAX_N + 1):
        let factor: Int64 = if n % Int(p) == 0: 1 else: Int64(n)
        unit_prefix[n] = unit_prefix[n - 1] * factor % modulus
        p_free_factorial[n] = unit_prefix[n] * p_free_factorial[n // Int(p)] % modulus
        valuation[n] = UInt16(n // Int(p) + Int(valuation[n // Int(p)]))
    let phi = modulus // p * (p - 1)
    for i in range(q):
        let n = Int(input[3 + 2 * i])
        let k = Int(input[4 + 2 * i])
        let p_power = Int(valuation[n]) - Int(valuation[k]) - Int(valuation[n - k])
        if p_power < Int(e):
            let denominator = p_free_factorial[k] * p_free_factorial[n - k] % modulus
            let inverse = bcp_pow_mod(denominator, phi - 1, modulus)
            let prime_factor = bcp_pow_mod(p, Int64(p_power), modulus)
            residues[i] = UInt32(p_free_factorial[n] * inverse % modulus * prime_factor % modulus)
    for i in range(q):
        for byte in range(4):
            output[4 * i + byte] = UInt8((residues[i] >> UInt(8 * byte)) & UInt32(255))
    Int64(required)
