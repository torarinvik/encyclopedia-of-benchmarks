from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N: Int64 = 1000000000000
const MAX_PARSEABLE_LENGTH = 2

fn ad_from_factors(value: Int64) -> Int64:
    if value < 2:
        return 0
    let original = value
    var remaining = value
    var derivative: Int64 = 0
    var factor: Int64 = 2
    while factor <= remaining // factor:
        if remaining % factor == 0:
            var exponent: Int64 = 0
            while remaining % factor == 0:
                remaining = remaining // factor
                exponent += 1
            derivative += (original // factor) * exponent
        if factor == 2:
            factor = 3
        else:
            factor += 2
    if remaining > 1:
        derivative += original // remaining
    return derivative

@export("arithmetic_derivative")
fn arithmetic_derivative(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 1:
        return -1
    let n = input[0]
    if n < 0 or n > MAX_N:
        return -1
    return ad_from_factors(n)
