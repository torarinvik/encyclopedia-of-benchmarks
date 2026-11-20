from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_INPUT = 35
comptime INVALID_RESULT = -1_000_001

fn feasible(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int,
            minimum_length: Int, threshold: Int64) -> Bool:
    var prefix = InlineArray[Int64, 33](fill=0)
    for index in range(n):
        prefix[index + 1] = prefix[index] + 1000 * input[index + 2] - threshold
    var minimum_prefix: Int64 = 9_223_372_036_854_775_807
    for end in range(minimum_length, n + 1):
        let eligible_start = end - minimum_length
        minimum_prefix = min(minimum_prefix, prefix[eligible_start])
        if prefix[end] >= minimum_prefix:
            return True
    return False

@export("binary_search_maximum_average_segment")
fn binary_search_maximum_average_segment(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(3) or length > c_size_t(MAX_INPUT):
        return INVALID_RESULT
    let n = Int(input[0])
    let minimum_length = Int(input[1])
    if n < 1 or n > MAX_N or minimum_length < 1 or minimum_length > n:
        return INVALID_RESULT
    if Int(length) != n + 2:
        return INVALID_RESULT
    for index in range(n):
        if input[index + 2] < -1000 or input[index + 2] > 1000:
            return INVALID_RESULT

    var low: Int64 = -1_000_000
    var high: Int64 = 1_000_001
    while high - low > 1:
        let middle = low + (high - low) // 2
        if feasible(input, n, minimum_length, middle):
            low = middle
        else:
            high = middle
    return low
