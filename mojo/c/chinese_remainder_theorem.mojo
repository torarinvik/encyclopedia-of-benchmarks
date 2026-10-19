from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn modular_inverse(value: Int64, modulus: Int64) -> Int64:
    var old_remainder = value % modulus
    var remainder = modulus
    var old_coefficient: Int64 = 1
    var coefficient: Int64 = 0
    while remainder != 0:
        let quotient = old_remainder // remainder
        let next_remainder = old_remainder - quotient * remainder
        old_remainder = remainder
        remainder = next_remainder
        let next_coefficient = old_coefficient - quotient * coefficient
        old_coefficient = coefficient
        coefficient = next_coefficient
    if old_remainder != 1: return -1
    old_coefficient %= modulus
    return old_coefficient + modulus if old_coefficient < 0 else old_coefficient

@export("chinese_remainder_theorem")
fn chinese_remainder_theorem(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 8 or length % 2 != 0: return -1
    var result: Int64 = 0
    var product: Int64 = 1
    for i in range(0, length, 2):
        let residue = values[i]
        let modulus = values[i + 1]
        if modulus < 2 or modulus > 1000 or residue < 0 or residue >= modulus: return -1
        let inverse = modular_inverse(product % modulus, modulus)
        if inverse < 0: return -1
        var difference = residue - result % modulus
        if difference < 0: difference += modulus
        let factor = (difference * inverse) % modulus
        result += product * factor
        product *= modulus
    return result
