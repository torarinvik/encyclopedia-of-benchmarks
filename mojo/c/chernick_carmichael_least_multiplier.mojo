from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_MULTIPLIER = 950560

fn ccm_is_prime(value: Int64) -> Bool:
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    var divisor: Int64 = 3
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 2
    return True

fn ccm_factors_are_prime(n: Int64, multiplier: Int64) -> Bool:
    if not ccm_is_prime(6 * multiplier + 1):
        return False
    if not ccm_is_prime(12 * multiplier + 1):
        return False

    var power_of_two: Int64 = 2
    var factor_index: Int64 = 1
    while factor_index <= n - 2:
        if not ccm_is_prime(9 * multiplier * power_of_two + 1):
            return False
        power_of_two *= 2
        factor_index += 1
    return True

@export("chernick_carmichael_least_multiplier")
fn chernick_carmichael_least_multiplier(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != c_size_t(1):
        return -1
    let n = input[0]
    if n < 3 or n > 9:
        return -1

    var step: Int64 = 1
    if n > 4:
        step = 1 << (n - 4)
    if n > 5:
        step *= 5

    var multiplier = step
    while multiplier <= Int64(MAX_MULTIPLIER):
        if ccm_factors_are_prime(n, multiplier):
            return multiplier
        multiplier += step
    return -1
