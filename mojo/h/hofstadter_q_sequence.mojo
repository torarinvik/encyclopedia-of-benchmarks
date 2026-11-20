from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_INDEX = 128
const MAX_INPUT_LENGTH = 2

fn hofstadter_q_impl(input: view[Int64]) -> Int64:
    if input.len != 1 or input[0] < 1 or input[0] > MAX_INDEX: return -1
    let target = Int(input[0])
    var q = InlineArray[Int64, 129](fill=0)
    q[1] = 1
    if target >= 2: q[2] = 1
    for n in range(3, target + 1):
        let left = Int64(n) - q[n - 1]
        let right = Int64(n) - q[n - 2]
        if left < 1 or right < 1 or left >= Int64(n) or right >= Int64(n): return -1
        q[n] = q[Int(left)] + q[Int(right)]
    return q[target]

@export("hofstadter_q_sequence")
fn hofstadter_q_sequence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    if length != 1: return -1
    var input_copy = InlineArray[Int64, 1]()
    input_copy[0] = input[0]
    return hofstadter_q_impl(input_copy[0:1])
