from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("container_with_most_water")
fn container_with_most_water(heights: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096: return -1
    for i in range(length):
        if heights[i] < 0 or heights[i] > 2147483647: return -1
    if length < 2: return 0
    var left: Int64 = 0
    var right = Int64(length) - 1
    var best: Int64 = 0
    while left < right:
        let lh = heights[left]
        let rh = heights[right]
        let h = lh if lh < rh else rh
        let area = h * (right - left)
        if area > best: best = area
        if lh <= rh: left += 1
        else: right -= 1
    return best
