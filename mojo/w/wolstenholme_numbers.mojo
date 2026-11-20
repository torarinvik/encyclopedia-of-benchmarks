from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 22
alias MAX_PARSEABLE_LENGTH = 2

fn wn_gcd(left_value: Int64, right_value: Int64) -> Int64:
    var left = left_value
    var right = right_value
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

fn wn_numerator(n: Int64) -> Int64:
    var numerator: Int64 = 0
    var denominator: Int64 = 1
    var k: Int64 = 1
    while k <= n:
        let square = k * k
        let common = wn_gcd(denominator, square)
        let scale = square // common
        numerator = numerator * scale + denominator // common
        denominator *= scale
        let factor = wn_gcd(numerator, denominator)
        numerator //= factor
        denominator //= factor
        k += 1
    return numerator

@export("wolstenholme_numbers")
fn wolstenholme_numbers(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 1: return -1
    let n = input[0]
    if n < 1 or n > MAX_N: return -1
    return wn_numerator(n)
