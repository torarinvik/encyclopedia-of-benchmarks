package automorphic_number

// Overflow-safe modular addition; both operands are below modulus.
add_mod :: proc "contextless" (left, right, modulus: u64) -> u64 {
    if left >= modulus - right do return left - (modulus - right)
    return left + right
}

multiply_mod :: proc "contextless" (left, right, modulus: u64) -> u64 {
    factor := left
    multiplier := right
    result: u64 = 0
    for multiplier != 0 {
        if (multiplier & 1) != 0 do result = add_mod(result, factor, modulus)
        multiplier >>= 1
        if multiplier != 0 do factor = add_mod(factor, factor, modulus)
    }
    return result
}

@(export)
automorphic_number :: proc "c" (n: i64) -> i64 {
    if n < 0 do return 0
    number := u64(n)
    modulus: u64 = 10
    for digits := number; digits >= 10; digits /= 10 {
        modulus *= 10
    }
    return i64(multiply_mod(number, number, modulus) == number)
}
