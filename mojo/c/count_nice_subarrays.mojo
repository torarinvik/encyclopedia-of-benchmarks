from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_nice_subarrays")
fn count_nice_subarrays(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or values[0] < 0 or values[0] > 4096 or values[1] < 1 or values[1] > 4096: return -1
    let n = values[0]
    let k = Int64(Int32(values[1]))
    if length != n + 2: return -1
    for i in range(n):
        if values[i + 2] < -2147483648 or values[i + 2] > 2147483647: return -1
    var memo = InlineArray[Int32, 4096](0)
    var left: Int64 = 0
    var odd_count: Int32 = 0
    var result: Int64 = 0
    for right in range(n):
        if (Int32(values[right + 2]) & 1) == 1: odd_count += 1
        if odd_count > k:
            left += Int64(memo[left])
            odd_count -= 1
        if odd_count == k:
            if memo[left] == 0:
                var even_count: Int64 = 0
                var temp = left
                while (Int32(values[temp + 2]) & 1) == 0:
                    even_count += 1
                    temp += 1
                memo[left] = Int32(even_count + 1)
            result += Int64(memo[left])
    return result
