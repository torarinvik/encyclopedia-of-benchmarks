from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 64
const MAX_INPUT = 67
const MAX_SEGMENTS = 65

fn gcd_nonnegative(left: Int64, right: Int64) -> Int64:
    var a = left
    var b = right
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

fn combine_value(mode: Int64, left: Int64, right: Int64) -> Int64:
    if mode == 0: return gcd_nonnegative(left, right)
    if mode == 1: return left | right
    return left & right

@export("distinct_subarray_aggregates")
fn distinct_subarray_aggregates(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let mode = input[0]
    let n_value = input[1]
    if mode < 0 or mode > 2 or n_value < 0 or n_value > MAX_N: return -1
    let n = Int(n_value)
    if length != c_size_t(2 + n): return -1

    var segment_value = InlineArray[Int64, MAX_SEGMENTS](fill=0)
    var segment_left = InlineArray[Int64, MAX_SEGMENTS](fill=0)
    var segment_right = InlineArray[Int64, MAX_SEGMENTS](fill=0)
    var segment_count = 0
    var aggregate_sum: Int64 = 0
    var suffix_distinct_count: Int64 = 0
    for right in range(n):
        let value = input[2 + right]
        if value < 0 or value > 255: return -1
        for j in range(segment_count):
            segment_value[j] = combine_value(mode, segment_value[j], value)
        segment_value[segment_count] = value
        segment_left[segment_count] = Int64(right)
        segment_right[segment_count] = Int64(right)
        segment_count += 1

        var write = 0
        for read in range(segment_count):
            if write > 0 and segment_value[read] == segment_value[write - 1]:
                segment_right[write - 1] = segment_right[read]
            else:
                segment_value[write] = segment_value[read]
                segment_left[write] = segment_left[read]
                segment_right[write] = segment_right[read]
                write += 1
        segment_count = write
        suffix_distinct_count += Int64(segment_count)
        for j in range(segment_count):
            aggregate_sum += segment_value[j] * (segment_right[j] - segment_left[j] + 1)
    return aggregate_sum * 1024 + suffix_distinct_count
