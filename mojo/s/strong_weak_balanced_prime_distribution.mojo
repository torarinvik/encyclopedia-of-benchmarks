from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_LIMIT: Int64 = 100_000
const SIEVE_LENGTH = 200_001

fn count(limit: Int64) -> Int64:
    var prime = InlineArray[Int64, SIEVE_LENGTH](fill=1)
    let ceiling = 2 * limit
    prime[0] = 0
    prime[1] = 0
    var divisor: Int64 = 2
    while divisor * divisor <= ceiling:
        if prime[Int(divisor)] != 0:
            var multiple = divisor * divisor
            while multiple <= ceiling:
                prime[Int(multiple)] = 0
                multiple += divisor
        divisor += 1

    var strong: Int64 = 0
    var weak: Int64 = 0
    var balanced: Int64 = 0
    var previous: Int64 = 0
    var current: Int64 = 0
    for candidate in range(2, Int(ceiling) + 1):
        if prime[candidate] == 0:
            continue
        if previous != 0 and current >= 3 and current <= limit:
            let twice = 2 * current
            let neighbors = previous + Int64(candidate)
            if twice > neighbors:
                strong += 1
            elif twice < neighbors:
                weak += 1
            else:
                balanced += 1
        previous = current
        current = Int64(candidate)
    return strong * 10_000_000_000 + weak * 100_000 + balanced

@export("strong_weak_balanced_prime_distribution")
fn strong_weak_balanced_prime_distribution(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 2:
        return -1
    let limit = input[0]
    if length != 1 or limit < 3 or limit > MAX_LIMIT:
        return -1
    return count(limit)
