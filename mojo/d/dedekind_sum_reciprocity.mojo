from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_MODULUS = 100_000
const MAX_LENGTH = 3
const RESULT_OFFSET: Int64 = 29_999_700_001

fn gcd(left_value: Int64, right_value: Int64) -> Int64:
    var left = left_value
    var right = right_value
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

fn scaled_sum(numerator: Int64, modulus: Int64) -> Int64:
    if modulus == 1: return 0
    let tail = scaled_sum(modulus % numerator, numerator)
    let top = numerator * numerator + modulus * modulus + 1 - 3 * numerator * modulus - modulus * tail
    return top // numerator

@export("dedekind_sum_reciprocity")
fn dedekind_sum_reciprocity(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let numerator = input[0]
    let modulus = input[1]
    if modulus < 1 or modulus > MAX_MODULUS or numerator < 0 or numerator >= modulus: return -1
    if gcd(numerator, modulus) != 1: return -1
    return RESULT_OFFSET + scaled_sum(numerator, modulus)
