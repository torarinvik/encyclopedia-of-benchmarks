from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_LENGTH = 8
const ALPHABET_SIZE = 26

fn factorial(value: Int64) -> Int64:
    var result: Int64 = 1
    for factor in range(2, Int(value) + 1): result *= factor
    return result

@export("alphabetic_anagrams")
fn alphabetic_anagrams(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 10: return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_LENGTH or Int(length) != Int(n_value) + 1: return -1
    let n = Int(n_value)
    var frequency = InlineArray[Int64, ALPHABET_SIZE](fill=0)
    for position in range(n):
        let symbol = input[position + 1]
        if symbol < 0 or symbol > 25: return -1
        frequency[Int(symbol)] += 1

    var denominator: Int64 = 1
    for symbol in range(ALPHABET_SIZE): denominator *= factorial(frequency[symbol])
    var ways = factorial(n_value) / denominator
    var rank: Int64 = 1
    var remaining = n_value
    for position in range(n):
        let actual = Int(input[position + 1])
        for smaller in range(actual):
            if frequency[smaller] > 0:
                rank += ways * frequency[smaller] / remaining
        ways = ways * frequency[actual] / remaining
        frequency[actual] -= 1
        remaining -= 1
    return rank
