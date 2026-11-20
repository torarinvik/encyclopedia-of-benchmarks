from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MIN_VALUE = -1_000_000_000
comptime MAX_VALUE = 1_000_000_000

fn muks_sift_down(mut values: InlineArray[Int64, MAX_N], root_start: Int, end: Int):
    var root = root_start
    while root < end // 2:
        var child = root * 2 + 1
        if child + 1 < end and values[child] < values[child + 1]:
            child += 1
        if values[root] >= values[child]:
            break
        let temporary = values[root]
        values[root] = values[child]
        values[child] = temporary
        root = child

fn muks_heap_sort(mut values: InlineArray[Int64, MAX_N], length: Int):
    var start = length // 2
    while start > 0:
        start -= 1
        muks_sift_down(values, start, length)
    var end = length
    while end > 1:
        end -= 1
        let temporary = values[0]
        values[0] = values[end]
        values[end] = temporary
        muks_sift_down(values, 0, end)

@export("minimum_unfairness_k_selection")
fn minimum_unfairness_k_selection(packed: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if packed == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > c_size_t(MAX_N + 2):
        return -1
    let n_value = packed[0]
    let k_value = packed[1]
    if n_value < 2 or n_value > MAX_N or k_value < 2 or k_value > n_value or length != c_size_t(n_value + 2):
        return -1

    let n = Int(n_value)
    let k = Int(k_value)
    var sorted = InlineArray[Int64, MAX_N](fill=0)
    for index in range(n):
        let value = packed[index + 2]
        if value < MIN_VALUE or value > MAX_VALUE:
            return -1
        sorted[index] = value
    muks_heap_sort(sorted, n)

    var best: Int64 = 2_000_000_001
    for first in range(n - k + 1):
        let width = sorted[first + k - 1] - sorted[first]
        if width < best:
            best = width
    return best
