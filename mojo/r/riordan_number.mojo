from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

const MAX_PARSEABLE_LENGTH: Int = 2
const MAX_N: Int64 = 30

fn riordan_number_value(n: Int) -> Int64:
    var values = List[Int64](length=31, fill=0)
    values[0] = 1
    for size in range(2, n + 1):
        let numerator = Int64(size - 1) * (2 * values[size - 1] + 3 * values[size - 2])
        values[size] = numerator // Int64(size + 1)
    return values[n]

@export("riordan_number")
fn riordan_number(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 1 or input[0] < 0 or input[0] > MAX_N:
        return -1
    return riordan_number_value(Int(input[0]))
