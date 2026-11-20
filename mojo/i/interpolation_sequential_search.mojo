from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 64
const MIN_VALUE: Int64 = -1000000
const MAX_VALUE: Int64 = 1000000

@export("interpolation_sequential_search")
fn interpolation_sequential_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 67: return -1
    let count_value = input[0]
    let target = input[1]
    if count_value < 0 or count_value > MAX_N or length != c_size_t(count_value + 2): return -1
    if target < MIN_VALUE or target > MAX_VALUE: return -1
    let count = Int(count_value)
    for i in range(count):
        let value = input[i + 2]
        if value < MIN_VALUE or value > MAX_VALUE: return -1
        if i > 0 and input[i + 1] >= value: return -1
    if count == 0: return -1
    let first = input[2]
    let last = input[count + 1]
    if target < first or target > last: return -1
    if count == 1: return 0 if first == target else -1
    let position = Int((target - first) * Int64(count - 1) / (last - first))
    let estimated = input[position + 2]
    if estimated == target: return Int64(position)
    if estimated < target:
        for i in range(position + 1, count):
            let value = input[i + 2]
            if value >= target: return Int64(i) if value == target else -1
    else:
        var i = position
        while i > 0:
            i -= 1
            let value = input[i + 2]
            if value <= target: return Int64(i) if value == target else -1
    return -1
