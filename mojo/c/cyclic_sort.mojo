from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cyclic_sort")
fn cyclic_sort(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 1024 or (length > 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var seen = InlineArray[UInt8, 1025](0)
    var sorted = InlineArray[Int64, 1024](0)
    for i in range(length):
        let v = values[i]
        if v < 1 or v > length or seen[v] != 0: return -1
        seen[v] = 1
        sorted[i] = v
    var index: Int64 = 0
    while index < length:
        let destination = sorted[index] - 1
        if destination == index: index += 1
        else:
            let temp = sorted[index]
            sorted[index] = sorted[destination]
            sorted[destination] = temp
    let bytes = length * 8
    if bytes > capacity or (bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    for i in range(length):
        let bits = UInt64(sorted[i])
        for b in range(8): output[i * 8 + b] = UInt8((bits >> (8 * b)) & 255)
    return length
