from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn gcd_i64(left_input: Int64, right_input: Int64) -> Int64:
    var left = left_input
    var right = right_input
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

fn pow_mod_i64(base_input: Int64, exponent_input: Int64, modulus: Int64) -> Int64:
    var result: Int64 = 1
    var base = base_input % modulus
    var exponent = exponent_input
    while exponent > 0:
        if (exponent & 1) != 0:
            result = (result * base) % modulus
        base = (base * base) % modulus
        exponent >>= 1
    return result

@export("pollard_p_minus_one_factorization")
fn pollard_p_minus_one_factorization(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3:
        return -1
    let number = input[0]
    let bound = input[1]
    let initial = input[2]
    if number < 2 or number > 1000000000 or bound < 2 or bound > 64 or initial < 1 or initial >= number:
        return -1
    var divisor = gcd_i64(initial, number)
    if divisor > 1:
        return divisor
    var state = initial
    for candidate in range(2, 65):
        if Int64(candidate) > bound:
            break
        var is_prime = True
        for trial in range(2, candidate):
            if candidate % trial == 0:
                is_prime = False
                break
        if not is_prime:
            continue
        let prime = Int64(candidate)
        if prime > bound:
            break
        var exponent = prime
        while exponent <= bound // prime:
            exponent *= prime
        state = pow_mod_i64(state, exponent, number)
        let difference = abs(state - 1)
        divisor = gcd_i64(difference, number)
        if divisor > 1:
            return divisor if divisor < number else 0
    return 0
