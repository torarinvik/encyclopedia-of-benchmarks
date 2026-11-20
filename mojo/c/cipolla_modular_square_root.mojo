from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn cipolla_normalize(value: Int64, prime: Int64) -> Int64:
    var remainder = value % prime
    if remainder < 0:
        remainder += prime
    return remainder

fn cipolla_modular_power(base_value: Int64, exponent_value: Int64, prime: Int64) -> Int64:
    var base = cipolla_normalize(base_value, prime)
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = (result * base) % prime
        exponent = exponent >> 1
        if exponent > 0:
            base = (base * base) % prime
    return result

fn cipolla_legendre_symbol(value: Int64, prime: Int64) -> Int64:
    let symbol = cipolla_modular_power(value, (prime - 1) / 2, prime)
    if symbol == prime - 1:
        return -1
    return symbol

fn cipolla_pair_real(a: Int64, b: Int64, c: Int64, e: Int64,
                     radicand: Int64, prime: Int64) -> Int64:
    return (a * c + radicand * b * e) % prime

fn cipolla_pair_imaginary(a: Int64, b: Int64, c: Int64, e: Int64,
                          prime: Int64) -> Int64:
    return (a * e + b * c) % prime

@export("cipolla_modular_square_root")
fn cipolla_modular_square_root(
    packed: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if packed == UnsafePointer[Int64, ImmutAnyOrigin]() or length != c_size_t(2):
        return -1
    let residue = packed[0]
    let prime = packed[1]
    if prime < 3 or prime > 1000003 or (prime & 1) == 0 or residue < 0 or residue >= prime:
        return -1
    if residue == 0:
        return 0
    if cipolla_legendre_symbol(residue, prime) != 1:
        return -1

    var parameter: Int64 = 0
    var radicand: Int64 = 0
    var found = False
    while parameter < prime:
        radicand = cipolla_normalize(parameter * parameter - residue, prime)
        if cipolla_legendre_symbol(radicand, prime) == -1:
            found = True
            break
        parameter += 1
    if not found:
        return -1

    var result_real: Int64 = 1
    var result_imaginary: Int64 = 0
    var base_real = parameter
    var base_imaginary: Int64 = 1
    var exponent = (prime + 1) / 2
    while exponent > 0:
        if (exponent & 1) != 0:
            let next_real = cipolla_pair_real(
                result_real, result_imaginary, base_real, base_imaginary, radicand, prime
            )
            let next_imaginary = cipolla_pair_imaginary(
                result_real, result_imaginary, base_real, base_imaginary, prime
            )
            result_real = next_real
            result_imaginary = next_imaginary
        exponent = exponent >> 1
        if exponent > 0:
            let next_base_real = cipolla_pair_real(
                base_real, base_imaginary, base_real, base_imaginary, radicand, prime
            )
            let next_base_imaginary = cipolla_pair_imaginary(
                base_real, base_imaginary, base_real, base_imaginary, prime
            )
            base_real = next_base_real
            base_imaginary = next_base_imaginary
    if result_imaginary != 0:
        return -1
    return min(result_real, prime - result_real)
