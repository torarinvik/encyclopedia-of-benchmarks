# Bounded Morrison-Brillhart CFRAC; see package README for provenance.
# Written independently from the documented arithmetic contract.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn cfrac_gcd(a: Int64, b: Int64) -> Int64:
    var x = a
    var y = b
    while y != 0:
        let remainder = x % y
        x = y
        y = remainder
    return x

fn cfrac_power(value: Int64, exponent: Int64, modulus: Int64) -> Int64:
    var x = value % modulus
    var e = exponent
    var result: Int64 = 1
    while e > 0:
        if (e & 1) != 0: result = (result * x) % modulus
        x = (x * x) % modulus
        e >>= 1
    return result

fn cfrac_prime(n: Int64) -> Bool:
    if n < 2: return False
    var d: Int64 = 2
    while d * d <= n:
        if n % d == 0: return False
        d += 1
    return True

fn cfrac_factor(n: Int64, selected: Int64, count: Int,
                residues: InlineArray[Int64, 48],
                exponents: InlineArray[Int64, 480],
                base: InlineArray[Int64, 10], base_count: Int) -> Int64:
    var x: Int64 = 1
    var sums = InlineArray[Int64, 10](fill=0)
    for i in range(count):
        if (selected & (Int64(1) << i)) == 0: continue
        x = (x * residues[i]) % n
        for j in range(base_count): sums[j] += exponents[10 * i + j]
    var y: Int64 = 1
    for j in range(base_count):
        y = (y * cfrac_power(base[j], sums[j] // 2, n)) % n
    var difference = x - y
    if difference < 0: difference = -difference
    var factor = cfrac_gcd(difference, n)
    if factor > 1 and factor < n: return factor
    factor = cfrac_gcd(x + y, n)
    if factor > 1 and factor < n: return factor
    return 0

@export("mallocbench_cfrac")
fn mallocbench_cfrac(input: UnsafePointer[Int64, ImmutAnyOrigin],
                     length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    let n = input[0]
    if n < 15 or n > 1000000 or (n & 1) == 0: return -1
    if input[1] < 2 or input[1] > 10 or input[2] < 1 or input[2] > 48: return -1
    let base_count = Int(input[1])
    let iterations = Int(input[2])
    var root: Int64 = 0
    while (root + 1) * (root + 1) <= n: root += 1
    if root * root == n: return -1

    var base = InlineArray[Int64, 10](fill=0)
    base[0] = 2
    var filled = 1
    var candidate: Int64 = 3
    while candidate <= 10000 and filled < base_count:
        if cfrac_prime(candidate):
            let residue = cfrac_power(n % candidate, (candidate - 1) // 2, candidate)
            if residue == 0: return -1
            if residue == 1:
                base[filled] = candidate
                filled += 1
        candidate += 2
    if filled != base_count: return -1

    var vectors = InlineArray[Int64, 11](fill=0)
    var combinations = InlineArray[Int64, 11](fill=0)
    var occupied = InlineArray[Bool, 11](fill=False)
    var residues = InlineArray[Int64, 48](fill=0)
    var exponents = InlineArray[Int64, 480](fill=0)
    var relations = 0
    var u = 2 * root
    var previous_u = u
    var quotient: Int64 = 0
    var denominator: Int64 = 1
    var previous_denominator = n - root * root
    var a: Int64 = 1
    var previous_a = root
    var sign: Int64 = 0

    for unused in range(iterations):
        let old_a = a
        a = (quotient * a + previous_a) % n
        previous_a = old_a
        let old_denominator = denominator
        denominator = quotient * (previous_u - u) + previous_denominator
        previous_denominator = old_denominator
        previous_u = u
        if denominator <= 0: return n
        quotient = 1
        var remainder = u - denominator
        if remainder >= denominator:
            quotient = u // denominator
            remainder = u % denominator
        u = 2 * root - remainder
        sign ^= 1
        if denominator == 1: return n

        var residual = denominator
        var vector = sign
        for j in range(base_count):
            var exponent: Int64 = 0
            while residual % base[j] == 0:
                residual //= base[j]
                exponent += 1
            exponents[10 * relations + j] = exponent
            if (exponent & 1) != 0: vector |= Int64(1) << (j + 1)
        if residual != 1: continue
        residues[relations] = a
        var selected = Int64(1) << relations
        relations += 1
        var inserted = False
        for bit in range(base_count + 1):
            if (vector & (Int64(1) << bit)) == 0: continue
            if occupied[bit]:
                vector ^= vectors[bit]
                selected ^= combinations[bit]
            else:
                occupied[bit] = True
                vectors[bit] = vector
                combinations[bit] = selected
                inserted = True
                break
        if not inserted:
            let factor = cfrac_factor(n, selected, relations, residues, exponents, base, base_count)
            if factor > 1: return factor
    return n
