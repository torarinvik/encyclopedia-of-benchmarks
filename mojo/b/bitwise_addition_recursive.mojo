@export("bitwise_addition_recursive")
fn bitwise_addition_recursive(number: Int64, other_number: Int64) abi("C") -> Int64:
    if number < 0 or number > 2_147_483_647 or other_number < 0 or other_number > 2_147_483_647: return -1
    var a = number; var b = other_number
    while b != 0:
        let carry = (a & b) << 1
        a = a ^ b; b = carry
    return a
