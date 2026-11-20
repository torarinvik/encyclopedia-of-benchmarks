from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_COUNT = 6
alias MAX_WORDS = 2

fn sw_small_prime(value: UInt64) -> Bool:
    if value < 2: return False
    var divisor: UInt64 = 2
    while divisor <= value // divisor:
        if value % divisor == 0: return False
        divisor += 1
    return True

fn sw_multiply_mod(left: UInt64, right: UInt64, modulus: UInt64) -> UInt64:
    return (left * right) % modulus

fn sw_power_mod(initial_base: UInt64, initial_exponent: UInt64, modulus: UInt64) -> UInt64:
    var base = initial_base % modulus
    var exponent = initial_exponent
    var result: UInt64 = 1
    while exponent != 0:
        if exponent & 1 != 0: result = sw_multiply_mod(result, base, modulus)
        exponent >>= 1
        if exponent != 0: base = sw_multiply_mod(base, base, modulus)
    return result

fn sw_prime_prefix(value: UInt64) -> Bool:
    let small_primes = InlineArray[UInt64, 12](2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
    let bases = InlineArray[UInt64, 3](2, 7, 61)
    if value < 2: return False
    for index in range(12):
        let prime = small_primes[index]
        if value == prime: return True
        if value % prime == 0: return False
    var odd_part = value - 1
    var twos = 0
    while odd_part & 1 == 0:
        odd_part >>= 1
        twos += 1
    for index in range(3):
        var witness = sw_power_mod(bases[index], odd_part, value)
        if witness == 1 or witness == value - 1: continue
        var round = 1
        while round < twos and witness != value - 1:
            witness = sw_multiply_mod(witness, witness, value)
            round += 1
        if witness != value - 1: return False
    return True

@export("smarandache_wellin_prime_prefix_scan")
fn smarandache_wellin_prime_prefix_scan(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_WORDS:
        return -1
    let count = input[0]
    if count < 0 or count > MAX_COUNT or length != 1: return -1

    var values = InlineArray[UInt64, 3]()
    var result_count = 0
    var prefix: UInt64 = 0
    var candidate: UInt64 = 2
    for _ in range(count):
        while not sw_small_prime(candidate):
            candidate += 1 if candidate == 2 else 2
        var scale: UInt64 = 10
        while scale <= candidate: scale *= 10
        prefix = prefix * scale + candidate
        if sw_prime_prefix(prefix):
            values[result_count] = prefix
            result_count += 1
        candidate += 1 if candidate == 2 else 2

    let byte_count = result_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count):
        return -2
    var staged = InlineArray[UInt8, 24]()
    for item in range(result_count):
        for byte in range(8):
            staged[item * 8 + byte] = UInt8((values[item] >> (byte * 8)) & 255)
    for byte in range(byte_count): output[byte] = staged[byte]
    return byte_count
