from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("merge_intervals")
fn merge_intervals(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 513:
        return -1
    if input[0] < 0 or input[0] > 256:
        return -1
    let count = Int(input[0])
    if Int(length) != 1 + 2 * count:
        return -1
    var starts = InlineArray[Int64, 256](fill=0)
    var ends = InlineArray[Int64, 256](fill=0)
    for i in range(count):
        let start = input[1 + 2 * i]
        let end = input[2 + 2 * i]
        if start < -2147483648 or start > 2147483647 or end < -2147483648 or end > 2147483647 or start > end:
            return -1
        starts[i] = start
        ends[i] = end
    for i in range(1, count):
        let start = starts[i]
        let end = ends[i]
        var j = i
        while j > 0 and starts[j - 1] > start:
            starts[j] = starts[j - 1]
            ends[j] = ends[j - 1]
            j -= 1
        starts[j] = start
        ends[j] = end
    var merged = 0
    for i in range(count):
        if merged > 0 and starts[i] <= ends[merged - 1]:
            if ends[i] > ends[merged - 1]:
                ends[merged - 1] = ends[i]
        else:
            starts[merged] = starts[i]
            ends[merged] = ends[i]
            merged += 1
    let bytes = 8 * merged
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    for i in range(merged):
        for byte in range(4):
            output[8 * i + byte] = UInt8((starts[i] >> (8 * byte)) & 255)
            output[8 * i + 4 + byte] = UInt8((ends[i] >> (8 * byte)) & 255)
    return Int64(bytes)
