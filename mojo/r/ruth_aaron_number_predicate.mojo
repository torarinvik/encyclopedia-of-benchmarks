from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 100000
alias MAX_PARSEABLE_LENGTH = 2

fn factor_sum_counted(value_arg: Int64) -> Int64:
    var value = value_arg
    var total: Int64 = 0
    var divisor: Int64 = 2
    while divisor <= value // divisor:
        while value % divisor == 0:
            total += divisor
            value //= divisor
        divisor += 1
    if value > 1: total += value
    return total

@export("ruth_aaron_number_predicate")
fn ruth_aaron_number_predicate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 1: return -1
    let n = input[0]
    if n < 1 or n > MAX_N: return -1
    if factor_sum_counted(n) == factor_sum_counted(n + 1): return 1
    return 0
