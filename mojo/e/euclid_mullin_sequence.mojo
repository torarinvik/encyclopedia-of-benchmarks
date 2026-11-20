from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_PARSEABLE_LENGTH: Int = 2
const MAX_N: Int64 = 8

fn least_prime_factor(value: Int64) -> Int64:
    var divisor: Int64 = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            return divisor
        divisor += 1
    return value

fn euclid_mullin_term(index: Int64) -> Int64:
    var product: Int64 = 1
    var term: Int64 = 1
    for _ in range(Int(index)):
        term = least_prime_factor(product + 1)
        product *= term
    return term

@export("euclid_mullin_sequence")
fn euclid_mullin_sequence(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 1:
        return -1
    let index = input[0]
    if index < 1 or index > MAX_N:
        return -1
    return euclid_mullin_term(index)
