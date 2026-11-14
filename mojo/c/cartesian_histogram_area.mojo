# Uncompiled and unexecuted Cartesian-tree histogram draft.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("cartesian_histogram_area")
fn cartesian_histogram_area(heights: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length == 0: return 0
    if heights == UnsafePointer[Int64, ImmutAnyOrigin]() or length > 64: return -9223372036854775807-1
    let n = Int(length)
    for i in range(n):
        if heights[i] < 0 or heights[i] > 1000000: return -9223372036854775807-1
    var left = List[Int](length=64, fill=n)
    var right = List[Int](length=64, fill=n)
    var stack = List[Int](length=64, fill=0)
    var order = List[Int](length=64, fill=0)
    var sizes = List[Int](length=64, fill=0)
    var top = 0
    for i in range(n):
        var last = n
        while top > 0 and heights[stack[top-1]] > heights[i]:
            top -= 1
            last = stack[top]
        if top > 0: right[stack[top-1]] = i
        left[i] = last
        stack[top] = i
        top += 1
    let root = stack[0]
    top = 1
    stack[0] = root
    var used = 0
    while top > 0:
        top -= 1
        let node = stack[top]
        order[used] = node
        used += 1
        if left[node] < n:
            stack[top] = left[node]
            top += 1
        if right[node] < n:
            stack[top] = right[node]
            top += 1
    var best: Int64 = 0
    while used > 0:
        used -= 1
        let node = order[used]
        sizes[node] = 1
        if left[node] < n: sizes[node] += sizes[left[node]]
        if right[node] < n: sizes[node] += sizes[right[node]]
        let area = heights[node]*Int64(sizes[node])
        if area > best: best = area
    return best
