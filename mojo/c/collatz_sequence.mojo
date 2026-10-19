from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn collatz_next(value: Int64) -> Int64:
    return value / 2 if value % 2 == 0 else 3 * value + 1

@export("collatz_sequence")
fn collatz_sequence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1 or input[0] < 1 or input[0] > 1000000: return -1
    var current = input[0]
    var term_count: Int64 = 1
    while current != 1:
        current = collatz_next(current)
        term_count += 1
    let required = term_count * 8
    if capacity < required or output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    current = input[0]
    var offset: Int64 = 0
    while True:
        let bits = UInt64(current)
        for b in range(8): output[offset + b] = UInt8((bits >> (8 * b)) & 255)
        offset += 8
        if current == 1: break
        current = collatz_next(current)
    return offset
