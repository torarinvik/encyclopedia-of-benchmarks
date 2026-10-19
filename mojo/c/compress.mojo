from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("compress")
fn compress(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let count = input[0]
    if count < 0 or count > 64 or length != 1 + count: return -1
    for i in range(count):
        if input[1 + i] < -2147483648 or input[1 + i] > 2147483647: return -1
    let max_bytes = count * 4
    if output_capacity < max_bytes or (max_bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var staged = InlineArray[UInt8, 256](0)
    var result_count: Int64 = 0
    var previous: Int64 = 0
    for i in range(count):
        let value = input[1 + i]
        if i == 0 or value != previous:
            let bits = UInt32(value)
            for b in range(4): staged[4 * result_count + b] = UInt8((bits >> (8 * b)) & 255)
            result_count += 1
        previous = value
    for i in range(result_count * 4): output[i] = staged[i]
    return result_count
