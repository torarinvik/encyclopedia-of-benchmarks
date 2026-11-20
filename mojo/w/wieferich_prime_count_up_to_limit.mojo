from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_LIMIT = 5000
const MAX_PARSEABLE_LENGTH = 2

fn modular_power(base_value: Int64, exponent_value: Int64, modulus: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = (result * base) % modulus
        base = (base * base) % modulus
        exponent >>= 1
    return result

fn count_wieferich(limit: Int) -> Int64:
    var prime = InlineArray[UInt8, 5001]()
    for n in range(limit + 1): prime[n] = 1
    prime[0] = 0
    prime[1] = 0
    var divisor = 2
    while divisor * divisor <= limit:
        if prime[divisor] != 0:
            var multiple = divisor * divisor
            while multiple <= limit:
                prime[multiple] = 0
                multiple += divisor
        divisor += 1
    var count: Int64 = 0
    for p in range(3, limit + 1, 2):
        if prime[p] != 0:
            let p64 = Int64(p)
            if modular_power(2, p64 - 1, p64 * p64) == 1: count += 1
    return count

@export("wieferich_prime_count_up_to_limit")
fn wieferich_prime_count_up_to_limit(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 1: return -1
    let limit = input[0]
    if limit < 2 or limit > MAX_LIMIT: return -1
    return count_wieferich(Int(limit))
