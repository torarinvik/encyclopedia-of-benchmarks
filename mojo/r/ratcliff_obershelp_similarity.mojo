from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_TEXT = 32
const MAX_INPUT_LENGTH = 67

fn longest_match(input: view[Int64], first_base: Int, second_base: Int,
                 a0: Int, a1: Int, b0: Int, b1: Int) -> Int64:
    var dp = InlineArray[Int64, 33](fill=0)
    var best_length = 0
    var best_a = 0
    var best_b = 0
    for i in range(a0, a1):
        var diagonal: Int64 = 0
        for column in range(1, b1 - b0 + 1):
            let old = dp[column]
            let j = b0 + column - 1
            if input[first_base + i] == input[second_base + j]:
                let current = Int(diagonal) + 1
                dp[column] = Int64(current)
                if current > best_length:
                    best_length = current
                    best_a = i + 1 - current
                    best_b = j + 1 - current
            else:
                dp[column] = 0
            diagonal = old
    Int64(best_length * 4096 + best_a * 64 + best_b)

fn matched_characters(input: view[Int64], first_base: Int, second_base: Int,
                      a0: Int, a1: Int, b0: Int, b1: Int) -> Int64:
    if a0 >= a1 or b0 >= b1:
        return 0
    let packed = Int(longest_match(input, first_base, second_base, a0, a1, b0, b1))
    let block = packed // 4096
    if block == 0:
        return 0
    let rest = packed % 4096
    let a = rest // 64
    let b = rest % 64
    return (
        Int64(block)
        + matched_characters(input, first_base, second_base, a0, a, b0, b)
        + matched_characters(input, first_base, second_base,
                             a + block, a1, b + block, b1)
    )

fn compute(input: view[Int64]) -> Int64:
    let length = input.len()
    if length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    if input[0] < 0 or input[0] > Int64(MAX_TEXT) or input[1] < 0 or input[1] > Int64(MAX_TEXT):
        return -1
    let first_length = Int(input[0])
    let second_length = Int(input[1])
    if length != 2 + first_length + second_length:
        return -1
    for index in range(first_length + second_length):
        let byte = input[2 + index]
        if byte < 1 or byte > 127:
            return -1
    if first_length == 0 or second_length == 0:
        return 0
    let common = matched_characters(input, 2, 2 + first_length,
                                    0, first_length, 0, second_length)
    (200 * common) // Int64(first_length + second_length)

@export("ratcliff_obershelp_similarity")
fn ratcliff_obershelp_similarity(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    var local = InlineArray[Int64, 67](fill=0)
    for index in range(Int(length)):
        local[index] = input[index]
    compute(local[0:Int(length)])
