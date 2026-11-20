from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_INDEX = 8192
const MAX_INPUT_LENGTH = 2

fn hofstadter_conway_10000_impl(input: view[Int64]) -> Int64:
    if input.len != 1 or input[0] < 2 or input[0] > MAX_INDEX: return -1
    let target = Int(input[0])
    var a = InlineArray[Int64, 8193](fill=0)
    a[1] = 1
    a[2] = 1
    for n in range(3, target + 1):
        let previous = a[n - 1]
        let other = Int64(n) - previous
        if previous < 1 or previous >= Int64(n) or other < 1 or other >= Int64(n): return -1
        a[n] = a[Int(previous)] + a[Int(other)]
    return a[target]

@export("hofstadter_conway_10000_sequence")
fn hofstadter_conway_10000_sequence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    if length != 1: return -1
    var input_copy = InlineArray[Int64, 1]()
    input_copy[0] = input[0]
    return hofstadter_conway_10000_impl(input_copy[0:1])
