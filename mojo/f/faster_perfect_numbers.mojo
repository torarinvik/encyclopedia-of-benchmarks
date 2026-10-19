from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn perfect_prime(n: UInt64) -> Bool:
    if n < 2: return False
    var d: UInt64 = 2
    while d * d <= n:
        if n % d == 0: return False
        d += 1
    return True

fn mersenne_is_prime(p: UInt64) -> Bool:
    if p == 2: return True
    if p < 2: return False
    let modulus = (UInt64(1) << p) - 1
    var residue: UInt64 = 4
    for i in range(p - 2): residue = (residue * residue - 2) % modulus
    return residue == 0

@export("faster_perfect_numbers")
fn faster_perfect_numbers(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if value < 0 or value > 2305843009213693951: return -1
    var scaled = UInt64(value) * 8 + 1
    var limit: UInt64 = 0
    while scaled >= 4:
        scaled /= 4
        limit += 1
    var perfects = InlineArray[Int64, 8](0)
    var count: Int64 = 0
    for p in range(UInt64(2), limit + 1):
        if not perfect_prime(p) or not mersenne_is_prime(p): continue
        let m = (UInt64(1) << p) - 1
        let perfect = m * (UInt64(1) << (p - 1))
        if perfect <= UInt64(value):
            perfects[count] = Int64(perfect)
            count += 1
    let bytes = count * 8
    if bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    if capacity < bytes: return -2
    for i in range(count):
        let bits = UInt64(perfects[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
