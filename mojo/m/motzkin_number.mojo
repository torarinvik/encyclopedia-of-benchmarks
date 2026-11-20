from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

const MAX_PARSEABLE_LENGTH: Int = 2
const MAX_N: Int64 = 30

fn motzkin_number_value(n: Int) -> Int64:
    var values = List[Int64](length=31, fill=0)
    values[0] = 1
    if n >= 1:
        values[1] = 1
    for size in range(2, n + 1):
        var total = values[size - 1]
        for left in range(size - 1):
            total += values[left] * values[size - 2 - left]
        values[size] = total
    return values[n]

@export("motzkin_number")
fn motzkin_number(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 1 or input[0] < 0 or input[0] > MAX_N:
        return -1
    return motzkin_number_value(Int(input[0]))
