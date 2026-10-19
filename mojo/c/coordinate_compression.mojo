from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("coordinate_compression")
fn coordinate_compression(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or input[0] < 0 or input[0] > 128: return -1
    let n = input[0]
    if length != n + 1: return -1
    var sorted = InlineArray[Int64, 128](0)
    for i in range(n):
        let value = input[i + 1]
        if value < -2147483648 or value > 2147483647: return -1
        sorted[i] = value
    if capacity < 8 * n or (n > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    for i in range(1, n):
        let key = sorted[i]
        var j = i
        while j > 0 and sorted[j - 1] > key:
            sorted[j] = sorted[j - 1]
            j -= 1
        sorted[j] = key
    var ranks = InlineArray[Int64, 128](0)
    var rank: Int64 = -1
    var previous: Int64 = 0
    for i in range(n):
        if i == 0 or sorted[i] != previous: rank += 1
        ranks[i] = rank
        previous = sorted[i]
    var staged = InlineArray[Int64, 128](0)
    for i in range(n):
        var low: Int64 = 0
        var high = n
        while low < high:
            let middle = low + (high - low) / 2
            if sorted[middle] < input[i + 1]: low = middle + 1
            else: high = middle
        staged[i] = ranks[low]
    for i in range(n):
        let bits = UInt64(staged[i])
        for b in range(8): output[8 * i + b] = UInt8((bits >> (8 * b)) & 255)
    return 8 * n
