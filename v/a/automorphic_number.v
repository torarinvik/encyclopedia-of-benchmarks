module automorphic_number

// Overflow-safe modular addition; both operands are below modulus.
fn add_mod(left u64, right u64, modulus u64) u64 {
    if left >= modulus - right { return left - (modulus - right) }
    return left + right
}

fn multiply_mod(input_left u64, input_right u64, modulus u64) u64 {
    mut left := input_left
    mut right := input_right
    mut result := u64(0)
    for right != 0 {
        if (right & 1) != 0 { result = add_mod(result, left, modulus) }
        right >>= 1
        if right != 0 { left = add_mod(left, left, modulus) }
    }
    return result
}

@[export: 'automorphic_number']
pub fn automorphic_number(n i64) i64 {
    if n < 0 { return 0 }
    number := u64(n)
    mut modulus := u64(10)
    mut digits := number
    for digits >= 10 {
        digits /= 10
        modulus *= 10
    }
    if multiply_mod(number, number, modulus) == number { return 1 }
    return 0
}
