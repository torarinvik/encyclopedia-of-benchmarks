from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MODULUS = Int64(1000000007)

fn sparse_fingerprint_power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if exponent & 1 != 0: result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result

@export("turnstile_one_sparse_fingerprint_recovery")
fn turnstile_one_sparse_fingerprint_recovery(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 260: return -1
    let n = input[0]
    let q = input[1]
    let base = input[2]
    if n < 1 or n > 64 or q < 0 or q > 128 or base < 1 or base >= MODULUS or length != c_size_t(3 + 2 * q): return -1
    var mass: Int64 = 0
    var weighted: Int64 = 0
    var fingerprint: Int64 = 0
    for i in range(Int(q)):
        let index = input[3 + 2 * i]
        let delta = input[4 + 2 * i]
        if index < 0 or index >= n or delta < -1000 or delta > 1000: return -1
        mass += delta
        weighted += delta * index
        fingerprint = (fingerprint + delta * sparse_fingerprint_power(base, index)) % MODULUS
        if fingerprint < 0: fingerprint += MODULUS
    if mass == 0 or weighted % mass != 0: return 0
    let index = weighted // mass
    if index < 0 or index >= n: return 0
    var expected = mass * sparse_fingerprint_power(base, index) % MODULUS
    if expected < 0: expected += MODULUS
    if fingerprint == expected: return index + 1
    return 0
