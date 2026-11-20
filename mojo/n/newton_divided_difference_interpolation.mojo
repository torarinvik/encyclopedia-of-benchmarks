from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MODULUS: Int64 = 998244353
const MAX_NODES = 12
const MAX_LENGTH = 27

fn mod_pow(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) == 1:
            result = result * base % MODULUS
        base = base * base % MODULUS
        exponent = exponent >> 1
    return result

@export("newton_divided_difference_interpolation")
fn newton_divided_difference_interpolation(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > MAX_LENGTH:
        return -1
    if input[0] < 1 or input[0] > MAX_NODES:
        return -1
    let count = Int(input[0])
    if length != c_size_t(2 + 2 * count):
        return -1
    var nodes = InlineArray[Int64, MAX_NODES](fill=0)
    var differences = InlineArray[Int64, MAX_NODES](fill=0)
    for i in range(count):
        nodes[i] = input[1 + i]
        differences[i] = input[1 + count + i]
        if nodes[i] < 0 or nodes[i] >= MODULUS or differences[i] < 0 or differences[i] >= MODULUS:
            return -1
        for j in range(i):
            if nodes[i] == nodes[j]:
                return -1
    let query = input[Int(length) - 1]
    if query < 0 or query >= MODULUS:
        return -1
    for order in range(1, count):
        for offset in range(count - order):
            let i = count - 1 - offset
            var numerator = differences[i] - differences[i - 1]
            if numerator < 0:
                numerator += MODULUS
            var denominator = nodes[i] - nodes[i - order]
            if denominator < 0:
                denominator += MODULUS
            differences[i] = numerator * mod_pow(denominator, MODULUS - 2) % MODULUS
    var result = differences[count - 1]
    for offset in range(count - 1):
        let i = count - 2 - offset
        var factor = query - nodes[i]
        if factor < 0:
            factor += MODULUS
        result = (result * factor + differences[i]) % MODULUS
    return result
