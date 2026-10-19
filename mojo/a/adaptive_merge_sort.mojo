from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List

fn merge_range(mut values: List[Int64], mut scratch: List[Int64], low: Int, high: Int):
    if high - low <= 1:
        return
    let middle = low + (high - low) / 2
    merge_range(values, scratch, low, middle)
    merge_range(values, scratch, middle, high)
    if values[middle - 1] <= values[middle]:
        return
    var left = low
    var right = middle
    var out = low
    while left < middle and right < high:
        if values[left] <= values[right]:
            scratch[out] = values[left]
            left += 1
        else:
            scratch[out] = values[right]
            right += 1
        out += 1
    while left < middle:
        scratch[out] = values[left]
        left += 1
        out += 1
    while right < high:
        scratch[out] = values[right]
        right += 1
        out += 1
    for i in range(low, high):
        values[i] = scratch[i]

@export("adaptive_merge_sort")
fn adaptive_merge_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C"):
    if length > 1024 or (length > 0 and values == UnsafePointer[Int64, MutAnyOrigin]()):
        return
    let n = Int(length)
    var copy = List[Int64](length=n, fill=0)
    var scratch = List[Int64](length=n, fill=0)
    for i in range(n):
        copy[i] = values[i]
    merge_range(copy, scratch, 0, n)
    for i in range(n):
        values[i] = copy[i]
