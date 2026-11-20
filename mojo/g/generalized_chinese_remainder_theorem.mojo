from std.collections import InlineArray
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
    old_coefficient %= modulus
    return old_coefficient + modulus if old_coefficient < 0 else old_coefficient

@export("generalized_chinese_remainder_theorem")
fn generalized_chinese_remainder_theorem(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 10:
        return -1
    let count = input[0]
    if count < 1 or count > 4 or Int(length) != 1 + 2 * Int(count):
        return -1
    var product: Int64 = 1
    for index in range(Int(count)):
        let residue = input[1 + 2 * index]
        let modulus = input[2 + 2 * index]
        if modulus < 2 or modulus > 64 or residue < 0 or residue >= modulus:
            return -1
        if product > 16777216 // modulus:
            return -1
        product *= modulus

    var powers = InlineArray[Int64, 65](fill=0)
    var residues = InlineArray[Int64, 65](fill=0)
    for index in range(Int(count)):
        let residue = input[1 + 2 * index]
        var remaining = input[2 + 2 * index]
        var prime: Int64 = 2
        while prime <= remaining:
            if remaining % prime == 0:
                var prime_power: Int64 = 1
                while remaining % prime == 0:
                    remaining //= prime
                    prime_power *= prime
                if prime_power > powers[Int(prime)]:
                    powers[Int(prime)] = prime_power
                    residues[Int(prime)] = residue % prime_power
            prime += 1
    for index in range(Int(count)):
        let residue = input[1 + 2 * index]
        var remaining = input[2 + 2 * index]
        var prime: Int64 = 2
        while prime <= remaining:
            if remaining % prime == 0:
                var prime_power: Int64 = 1
                while remaining % prime == 0:
                    remaining //= prime
                    prime_power *= prime
                if residues[Int(prime)] % prime_power != residue % prime_power:
                    return -2
            prime += 1

    var solution: Int64 = 0
    var combined_modulus: Int64 = 1
    for prime in range(2, 65):
        let modulus = powers[prime]
        if modulus == 0:
            continue
        let inverse = modular_inverse(combined_modulus % modulus, modulus)
        var difference = (residues[prime] - solution % modulus) % modulus
        if difference < 0:
            difference += modulus
        let multiplier = difference * inverse % modulus
        solution += combined_modulus * multiplier
        combined_modulus *= modulus
        solution %= combined_modulus
    return solution
