from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 10
alias SEARCH_MAX = 64
alias MAX_PARSEABLE_LENGTH = 2

fn is_prime_trial(value: Int64) -> Bool:
    if value < 2: return False
    var divisor: Int64 = 2
    while divisor <= value // divisor:
        if value % divisor == 0: return False
        divisor += 1
    return True

fn fortunate_term(n: Int64) -> Int64:
    var primorial: Int64 = 1
    var primes_found: Int64 = 0
    var candidate: Int64 = 2
    while primes_found < n:
        if is_prime_trial(candidate):
            primorial *= candidate
            primes_found += 1
        candidate += 1
    var offset: Int64 = 2
    while offset <= SEARCH_MAX:
        if is_prime_trial(primorial + offset): return offset
        offset += 1
    return -2

@export("fortunate_numbers")
fn fortunate_numbers(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 1: return -1
    let n = input[0]
    if n < 1 or n > MAX_N: return -1
    return fortunate_term(n)
