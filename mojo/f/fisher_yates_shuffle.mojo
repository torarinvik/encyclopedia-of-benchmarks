from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List
from std.collections import InlineArray

fn fisher_store_i32(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt32(Int32(value))
    for b in range(4): output[offset + b] = UInt8((bits >> (8 * b)) & UInt32(255))

@export("fisher_yates_shuffle")
fn fisher_yates_shuffle(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 1025: return -1
    let seed = input[0]
    let n = Int(length) - 1
    if seed < 1 or seed > 2147483646: return -1
    var values = InlineArray[Int32, 1024](fill=0)
    for i in range(n):
        let x = input[i + 1]
        if x < -2147483648 or x > 2147483647: return -1
        values[i] = Int32(x)
    let bytes = n * 4
    if capacity < c_size_t(bytes) or (bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var state = seed
    var remaining = n
    while remaining > 1:
        state = (state * 48271) % 2147483647
        let j = Int(state % Int64(remaining))
        let t = values[remaining - 1]
        values[remaining - 1] = values[j]
        values[j] = t
        remaining -= 1
    for i in range(n): fisher_store_i32(output, i * 4, Int64(values[i]))
    return Int64(n)
