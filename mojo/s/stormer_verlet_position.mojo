from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn store_i64_le(inout output: InlineArray[UInt8, 256], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("stormer_verlet_position")
fn stormer_verlet_position(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t)
                           abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 33: return -1
    let count_value = input[0]
    if count_value < 2 or count_value > 32: return -1
    if length != c_size_t(count_value + 1): return -1
    if input[1] < -1024 or input[1] > 1024 or input[2] < -1024 or input[2] > 1024: return -1
    let count = Int(count_value)
    for step in range(count - 2):
        if input[3 + step] < -64 or input[3 + step] > 64: return -1

    let byte_count = 8 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
    var staged = InlineArray[UInt8, 256]()
    var previous = input[1]
    var current = input[2]
    store_i64_le(staged, 0, previous)
    store_i64_le(staged, 8, current)
    for index in range(2, count):
        let next = 2 * current - previous + input[index + 1]
        store_i64_le(staged, 8 * index, next)
        previous = current
        current = next
    for byte in range(byte_count): output[byte] = staged[byte]
    return Int64(byte_count)
