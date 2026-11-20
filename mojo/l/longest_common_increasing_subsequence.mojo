from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_INPUT = 67

fn lcis_impl(input: view[Int64]) -> Int64:
    if input.len() < 2 or input.len() > MAX_INPUT: return -1
    let n = input[0]
    let m = input[1]
    if n < 0 or n > 32 or m < 0 or m > 32 or input.len() != 2 + Int(n + m): return -1
    for index in range(Int(n + m)):
        if input[2 + index] < -16 or input[2 + index] > 16: return -1
    var ending_at = InlineArray[Int64, 32](fill=0)
    for i in range(Int(n)):
        let value = input[2 + i]
        var best_smaller: Int64 = 0
        for j in range(Int(m)):
            let other = input[2 + Int(n) + j]
            if value > other and ending_at[j] > best_smaller:
                best_smaller = ending_at[j]
            elif value == other and best_smaller + 1 > ending_at[j]:
                ending_at[j] = best_smaller + 1
    var answer: Int64 = 0
    for j in range(Int(m)):
        if ending_at[j] > answer: answer = ending_at[j]
    answer

@export("longest_common_increasing_subsequence")
fn longest_common_increasing_subsequence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    var values = InlineArray[Int64, MAX_INPUT]()
    for index in range(Int(length)):
        values[index] = input[index]
    lcis_impl(values[0:Int(length)])
