from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_COUNT = 256
comptime MAX_INPUT = 259

@export("shortest_subarray_with_sum_at_least_k")
fn shortest_subarray_with_sum_at_least_k(
        input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let target = input[0]
    let count = input[1]
    if target < -4096 or target > 4096 or count < 0 or count > MAX_COUNT:
        return -1
    let n = Int(count)
    if length != c_size_t(n + 2):
        return -1

    var prefix = InlineArray[Int64, 257](fill=0)
    for index in range(n):
        let value = input[index + 2]
        if value < -1000 or value > 1000:
            return -1
        prefix[index + 1] = prefix[index] + value

    var deque = InlineArray[Int, 257](fill=0)
    var head = 0
    var tail = 0
    var best = n + 1
    for right in range(n + 1):
        while head < tail and prefix[right] - prefix[deque[head]] >= target:
            let width = right - deque[head]
            if width < best:
                best = width
            head += 1
        while head < tail and prefix[right] <= prefix[deque[tail - 1]]:
            tail -= 1
        deque[tail] = right
        tail += 1
    if best <= n:
        return Int64(best)
    return 0

