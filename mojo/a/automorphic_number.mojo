fn automorphic_add_mod(left: UInt64, right: UInt64, modulus: UInt64) -> UInt64:
    if left >= modulus - right: return left - (modulus - right)
    return left + right

fn automorphic_mul_mod(left0: UInt64, right0: UInt64, modulus: UInt64) -> UInt64:
    var left = left0
    var right = right0
    var result: UInt64 = 0
    while right != 0:
        if (right & 1) != 0: result = automorphic_add_mod(result, left, modulus)
        right >>= 1
        if right != 0: left = automorphic_add_mod(left, left, modulus)
    return result

@export("automorphic_number")
fn automorphic_number(n: Int64) abi("C") -> Int64:
    if n < 0: return 0
    let number = UInt64(n)
    var modulus: UInt64 = 10
    var digits = number
    while digits >= 10:
        modulus *= 10
        digits /= 10
    if automorphic_mul_mod(number, number, modulus) == number: return 1
    return 0
