from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 100000
alias MAX_PARSEABLE_LENGTH = 2

fn digit_sum(value_arg: Int64) -> Int64:
    var value = value_arg
    var sum: Int64 = 0
    while value > 0:
        sum += value % 10
        value //= 10
    return sum

fn digit_product(value_arg: Int64) -> Int64:
    var value = value_arg
    var product: Int64 = 1
    while value > 0:
        product *= value % 10
        value //= 10
    return product

fn digital_root(value_arg: Int64) -> Int64:
    var value = value_arg
    while value >= 10:
        value = digit_sum(value)
    return value

fn multiplicative_root(value_arg: Int64) -> Int64:
    var value = value_arg
    while value >= 10:
        value = digit_product(value)
    return value

fn is_dividuus(n: Int64) -> Bool:
    let sum = digit_sum(n)
    let product = digit_product(n)
    let root = digital_root(n)
    let mroot = multiplicative_root(n)
    if sum == 0 or product == 0 or root == 0 or mroot == 0: return False
    return n % sum == 0 and n % product == 0 and n % root == 0 and n % mroot == 0

@export("dividuus_number_predicate")
fn dividuus_number_predicate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 1: return -1
    let n = input[0]
    if n < 1 or n > MAX_N: return -1
    if is_dividuus(n): return 1
    return 0
