from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn fast_search_segment(v: UnsafePointer[Int64, ImmutAnyOrigin], begin: Int64, n: Int64, target: Int64, offset: Int64) -> Int64:
    if n == 0: return -1
    let first = v[begin]
    let last = v[begin + n - 1]
    if target < first or target > last: return -1
    if first == last: return offset if target == first else -1
    let interp = (n - 1) * (target - first) / (last - first)
    let mid = n / 2
    let left = mid if interp > mid else interp
    let right = interp if interp > mid else mid
    var from: Int64 = 0
    var to: Int64 = 0
    if target < v[begin + left]:
        if left == 0: return -1
        from = 0
        to = left - 1
    elif target < v[begin + right]:
        from = left
        to = right - 1
    else:
        from = right
        to = n - 1
    if to < from: return -1
    return fast_search_segment(v, begin + from, to - from + 1, target, offset + from)

@export("fast_searcher")
fn fast_searcher(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 67 or input[0] < 0 or input[0] > 64: return -2
    let n = input[0]
    if length != n + 2: return -2
    for i in range(n):
        let x = input[1 + i]
        if x < -1000 or x > 1000 or (i > 0 and input[i] >= x): return -2
    let target = input[length - 1]
    if target < -1000 or target > 1000: return -2
    return fast_search_segment(input, 1, n, target, 0)
