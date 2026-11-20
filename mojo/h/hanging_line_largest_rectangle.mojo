from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_LENGTH = 64
const MAX_HEIGHT: Int64 = 1_000_000
const INVALID_RESULT: Int64 = -9_223_372_036_854_775_808

@export("hanging_line_largest_rectangle")
fn hanging_line_largest_rectangle(heights: UnsafePointer[Int64, ImmutAnyOrigin],
                                  length: c_size_t) abi("C") -> Int64:
    if length == 0: return 0
    if heights == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(MAX_LENGTH):
        return INVALID_RESULT
    for i in range(Int(length)):
        if heights[i] < 0 or heights[i] > MAX_HEIGHT: return INVALID_RESULT

    var left = InlineArray[Int, MAX_LENGTH](fill=0)
    var right = InlineArray[Int, MAX_LENGTH](fill=0)
    for i in range(Int(length)):
        left[i] = i
        while left[i] > 0 and heights[i] <= heights[left[i] - 1]:
            left[i] = left[left[i] - 1]
    for i in range(Int(length) - 1, -1, -1):
        right[i] = i
        while right[i] + 1 < Int(length) and heights[i] <= heights[right[i] + 1]:
            right[i] = right[right[i] + 1]

    var best: Int64 = 0
    for i in range(Int(length)):
        let width = Int64(right[i] - left[i] + 1)
        let area = heights[i] * width
        if area > best: best = area
    return best
