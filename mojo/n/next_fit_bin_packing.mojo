from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn next_fit_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[8 * slot + byte] = UInt8(bits & 255)
        bits >>= 8

@export("next_fit_bin_packing")
fn next_fit_bin_packing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let count = input[0]
    if count < 0 or count > 64 or length != c_size_t(1 + count): return -1
    let n = Int(count)
    var assignments = InlineArray[Int64, 64](fill=0)
    var bins: Int64 = 0
    var remaining: Int64 = 0
    for i in range(n):
        let size = input[i + 1]
        if size < 1 or size > 1000000: return -1
        if bins == 0 or size > remaining:
            assignments[i] = bins
            bins += 1
            remaining = 1000000 - size
        else:
            assignments[i] = bins - 1
            remaining -= size
    let bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    next_fit_store(output, 0, bins)
    for i in range(n): next_fit_store(output, i + 1, assignments[i])
    return Int64(bytes)
