from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_INPUT_LENGTH = 2
const MAX_VALUE = 600_000
const MAX_K: Int64 = 50_000

fn build_prime_prefix(prefix: mutable view[UInt32]) -> None:
    prefix[0] = 0
    prefix[1] = 0
    for value in range(2, MAX_VALUE + 1):
        prefix[value] = 1
    var prime = 2
    while prime <= MAX_VALUE // prime:
        if prefix[prime] != 0:
            var multiple = prime * prime
            while multiple <= MAX_VALUE:
                prefix[multiple] = 0
                multiple += prime
        prime += 1
    for value in range(1, MAX_VALUE + 1):
        prefix[value] += prefix[value - 1]

fn is_prime(value: Int, prefix: view[UInt32]) -> Bool:
    return value >= 2 and prefix[value] - prefix[value - 1] == 1

fn count_tau_eight(limit: Int, prefix: view[UInt32]) -> Int64:
    var count: Int64 = 0
    var prime: Int64 = 2
    while True:
        var power: UInt64 = 1
        for _ in range(7):
            if power > UInt64(limit) // UInt64(prime):
                power = UInt64(limit) + 1
                break
            power *= UInt64(prime)
        if power > UInt64(limit): break
        if is_prime(Int(prime), prefix): count += 1
        prime += 1

    prime = 2
    while True:
        let cube = prime * prime * prime
        if cube > Int64(limit): break
        if is_prime(Int(prime), prefix):
            let q_max = Int(Int64(limit) // cube)
            count += Int64(prefix[q_max])
            if Int64(prime) <= Int64(q_max): count -= 1
        prime += 1

    prime = 2
    while prime * prime * prime < Int64(limit):
        if is_prime(Int(prime), prefix):
            var other = prime + 1
            while True:
                if prime > Int64(limit) // other: break
                let product = prime * other
                let last_prime = Int(Int64(limit) // product)
                if Int64(last_prime) <= other: break
                if is_prime(Int(other), prefix):
                    count += Int64(prefix[last_prime] - prefix[Int(other)])
                other += 1
        prime += 1
    return count

fn sequence_term(k: Int64) -> Int64:
    if k == 1: return 1
    var prime_prefix = InlineArray[UInt32, MAX_VALUE + 1]()
    build_prime_prefix(prime_prefix[0:MAX_VALUE + 1])
    let prefix_view: view[UInt32] = prime_prefix[0:MAX_VALUE + 1]
    let target = k - 1
    if count_tau_eight(MAX_VALUE, prefix_view) < target: return -1
    var low = 1
    var high = MAX_VALUE
    while low < high:
        let middle = low + (high - low) // 2
        if count_tau_eight(middle, prefix_view) >= target: high = middle
        else: low = middle + 1
    return Int64(low)

@export("cube_root_proper_divisor_product")
fn cube_root_proper_divisor_product(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    if length != 1: return -1
    let k = input[0]
    if k < 1 or k > MAX_K: return -1
    return sequence_term(k)
