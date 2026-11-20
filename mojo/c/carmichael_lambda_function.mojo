from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N: Int64 = 1024
const MAX_PARSEABLE_LENGTH = 2

fn gcd_i64(left_value: Int64, right_value: Int64) -> Int64:
    var left = left_value
    var right = right_value
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

fn lcm_i64(left: Int64, right: Int64) -> Int64:
    return left // gcd_i64(left, right) * right

fn prime_power_lambda(prime: Int64, exponent: Int, power: Int64) -> Int64:
    if prime == 2:
        if exponent == 1: return 1
        if exponent == 2: return 2
        return power // 4
    return (power // prime) * (prime - 1)

fn factorization_lambda(n: Int64) -> Int64:
    if n == 1: return 1
    var remaining = n
    var result: Int64 = 1
    var prime: Int64 = 2
    while prime * prime <= remaining:
        if remaining % prime != 0:
            if prime == 2: prime = 3
            else: prime += 2
            continue
        var exponent = 0
        var power: Int64 = 1
        while remaining % prime == 0:
            remaining = remaining // prime
            power *= prime
            exponent += 1
        result = lcm_i64(result, prime_power_lambda(prime, exponent, power))
        if prime == 2: prime = 3
        else: prime += 2
    if remaining > 1: result = lcm_i64(result, remaining - 1)
    return result

@export("carmichael_lambda_function")
fn carmichael_lambda_function(input: UnsafePointer[Int64, ImmutAnyOrigin],
                              length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let n = input[0]
    if n < 1 or n > MAX_N or length != 1:
        return -1
    return factorization_lambda(n)
