from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_T = 8
comptime MAX_K = 1_000_000_000
comptime MAX_P = 1_000

fn modular_power(base_input: Int64, exponent_input: Int64, modulus: Int64) -> Int64:
    var base = base_input % modulus
    var exponent = exponent_input
    var result = Int64(1) % modulus
    while exponent > 0:
        if exponent % 2 != 0: result = result * base % modulus
        base = base * base % modulus
        exponent //= 2
    return result

fn is_prime(value: Int64) -> Bool:
    if value < 2: return False
    var divisor = Int64(2)
    while divisor * divisor <= value:
        if value % divisor == 0: return False
        divisor += 1
    return True

fn factor_distinct(value_input: Int64, inout factors: InlineArray[Int64, 16]) -> Int:
    var value = value_input
    var count = Int(0)
    var divisor = Int64(2)
    while divisor * divisor <= value:
        if value % divisor == 0:
            factors[count] = divisor
            count += 1
            while value % divisor == 0: value //= divisor
        divisor += 1
    if value > 1:
        factors[count] = value
        count += 1
    return count

fn primitive_root(prime: Int64) -> Int64:
    if prime == 2: return 1
    let order = prime - 1
    var factors = InlineArray[Int64, 16]()
    let count = factor_distinct(order, factors)
    var candidate = Int64(2)
    while candidate < prime:
        var index = Int(0)
        while index < count and modular_power(candidate, order // factors[index], prime) != 1:
            index += 1
        if index == count: return candidate
        candidate += 1
    return -1

fn gcd_i64(a_input: Int64, b_input: Int64) -> Int64:
    var a = a_input
    var b = b_input
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

fn modular_inverse(value: Int64, modulus: Int64) -> Int64:
    var old_t = Int64(0)
    var new_t = Int64(1)
    var old_r = modulus
    var new_r = value % modulus
    while new_r != 0:
        let quotient = old_r // new_r
        let next_t = old_t - quotient * new_t
        let next_r = old_r - quotient * new_r
        old_t = new_t
        new_t = next_t
        old_r = new_r
        new_r = next_r
    if old_t < 0: old_t += modulus
    return old_t

fn kth_root(exponent: Int64, residue: Int64, prime: Int64) -> Int64:
    if exponent == 0: return 0 if residue == 1 else -1
    if residue == 0: return 0
    let order = prime - 1
    let generator = primitive_root(prime)
    var power = Int64(1)
    var discrete_log = Int64(-1)
    var candidate = Int64(0)
    while candidate < order:
        if power == residue:
            discrete_log = candidate
            break
        power = power * generator % prime
        candidate += 1
    if discrete_log < 0: return -1
    let common = gcd_i64(exponent, order)
    if discrete_log % common != 0: return -1
    let reduced_order = order // common
    var root_exponent = Int64(0)
    if reduced_order > 1:
        let inverse = modular_inverse((exponent // common) % reduced_order, reduced_order)
        root_exponent = (discrete_log // common) * inverse % reduced_order
    let root = modular_power(generator, root_exponent, prime)
    return root if modular_power(root, exponent, prime) == residue else -1

fn write_i64_le(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("kth_root_mod")
fn kth_root_mod(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    if length < 4 or length > 1 + 3 * MAX_T: return -1
    let count_value = input[0]
    if count_value < 1 or count_value > MAX_T: return -1
    let count = Int(count_value)
    if length != c_size_t(1 + 3 * count): return -1
    var triples = InlineArray[Int64, 24]()
    for test in range(count):
        let offset = 1 + 3 * test
        let exponent = input[offset]
        let residue = input[offset + 1]
        let prime = input[offset + 2]
        if exponent < 0 or exponent > MAX_K or prime < 2 or prime > MAX_P or residue < 0 or residue >= prime or not is_prime(prime): return -1
        triples[3 * test] = exponent
        triples[3 * test + 1] = residue
        triples[3 * test + 2] = prime
    let required = 8 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < required: return -2
    for test in range(count):
        let root = kth_root(triples[3 * test], triples[3 * test + 1], triples[3 * test + 2])
        write_i64_le(root, output, 8 * test)
    return Int64(required)
