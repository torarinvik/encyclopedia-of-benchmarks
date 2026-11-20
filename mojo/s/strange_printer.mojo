from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_LENGTH = 8
const TABLE_SIDE = 9

@export("strange_printer")
fn strange_printer(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 10: return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_LENGTH or Int(length) != Int(n_value) + 1: return -1
    let n = Int(n_value)
    for position in range(n):
        if input[position + 1] < 0 or input[position + 1] > 2: return -1
    if n == 0: return 0

    var dp = InlineArray[Int64, 81](fill=0)
    var left = n
    while left > 0:
        left -= 1
        dp[left * TABLE_SIDE + left] = 1
        for right in range(left + 1, n):
            var best = dp[(left + 1) * TABLE_SIDE + right] + 1
            for merge in range(left + 1, right + 1):
                if input[left + 1] != input[merge + 1]: continue
                var middle: Int64 = 0
                if merge > left + 1:
                    middle = dp[(left + 1) * TABLE_SIDE + merge - 1]
                let candidate = middle + dp[merge * TABLE_SIDE + right]
                if candidate < best: best = candidate
            dp[left * TABLE_SIDE + right] = best
    return dp[n - 1]
