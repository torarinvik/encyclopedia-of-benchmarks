from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_MODULUS = 1_000_000_000
const MAX_LENGTH = 3

fn reciprocity(numerator: Int64, denominator: Int64) -> Int64:
    var a = numerator
    var n = denominator
    var sign: Int64 = 1
    while a != 0:
        while (a & 1) == 0:
            a /= 2
            if n % 8 == 3 or n % 8 == 5: sign = -sign
        if a % 4 == 3 and n % 4 == 3: sign = -sign
        let old_a = a
        a = n
        n = old_a
        a %= n
    return sign if n == 1 else 0

@export("jacobi_symbol")
fn jacobi_symbol(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let numerator = input[0]
    let denominator = input[1]
    if denominator < 1 or denominator > MAX_MODULUS or (denominator & 1) == 0: return -1
    if numerator < 0 or numerator >= denominator: return -1
    return reciprocity(numerator, denominator) + 1
