from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn totient(value_input: Int64) -> Int64:
    var result = value_input
    var remaining = value_input
    if remaining % 2 == 0:
        result -= result // 2
        while remaining % 2 == 0: remaining //= 2
    var factor: Int64 = 3
    while factor <= remaining // factor:
        if remaining % factor == 0:
            result -= result // factor
            while remaining % factor == 0: remaining //= factor
        factor += 2
    if remaining > 1: result -= result // remaining
    return result

fn power_capped(base: Int64, exponent_input: Int64, cap: Int64) -> Int64:
    var result: Int64 = 1
    var factor = base if base < cap else cap
    var exponent = exponent_input
    while exponent > 0:
        if exponent % 2 != 0:
            result *= factor
            if result >= cap: return cap
        exponent //= 2
        if exponent > 0:
            factor *= factor
            if factor >= cap: factor = cap
    return result

fn tower_capped(base: Int64, height_input: Int64, cap: Int64) -> Int64:
    if height_input == 0: return Int64(1 if 1 < cap else cap)
    if base == 0: return Int64(1 if height_input % 2 == 0 else 0)
    if base == 1: return Int64(1 if 1 < cap else cap)
    var value: Int64 = 1
    if value >= cap: return cap
    var height = height_input
    while height > 0:
        value = power_capped(base, value, cap)
        if value >= cap: return cap
        height -= 1
    return value

fn modular_power(base_input: Int64, exponent_input: Int64, modulus: Int64) -> Int64:
    var result = 1 % modulus
    var base = base_input % modulus
    var exponent = exponent_input
    while exponent > 0:
        if exponent % 2 != 0: result = (result * base) % modulus
        exponent //= 2
        base = (base * base) % modulus
    return result

fn tetration(base: Int64, height: Int64, modulus: Int64) -> Int64:
    if modulus == 1: return 0
    if height == 0: return 1 % modulus
    if height == 1: return base % modulus
    let exponent_modulus = totient(modulus)
    var exponent = tetration(base, height - 1, exponent_modulus)
    if tower_capped(base, height - 1, exponent_modulus) >= exponent_modulus:
        exponent += exponent_modulus
    return modular_power(base, exponent, modulus)

@export("tetration_mod")
fn tetration_mod(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    let base = input[0]
    let height = input[1]
    let modulus = input[2]
    if base < 0 or base > 1000000000 or height < 0 or height > 1000000000:
        return -1
    if modulus < 1 or modulus > 1000000000: return -1
    return tetration(base, height, modulus)
