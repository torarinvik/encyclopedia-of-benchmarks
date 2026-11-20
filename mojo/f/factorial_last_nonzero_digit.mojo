from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer


fn digit_factor(digit: Int64) -> Int64:
    if digit == 0:
        return 1
    if digit == 1:
        return 1
    if digit == 2:
        return 2
    if digit == 3:
        return 6
    return 4


fn two_power_mod_10(exponent_mod_four: Int64) -> Int64:
    if exponent_mod_four == 0:
        return 1
    if exponent_mod_four == 1:
        return 2
    if exponent_mod_four == 2:
        return 4
    return 8


@export("factorial_last_nonzero_digit")
def factorial_last_nonzero_digit(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                 input_length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < 1 or input_length > 2:
        return -1
    if input_length != 1 or input[0] < 0:
        return -1

    var n = input[0]
    var result: Int64 = 1
    while n >= 5:
        let quotient = n / 5
        let remainder = n % 5
        result = result * digit_factor(remainder) % 10
        result = result * two_power_mod_10(quotient % 4) % 10
        n = quotient
    return result * digit_factor(n) % 10
