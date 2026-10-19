from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("combination_sum_iv")
fn combination_sum_iv(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 18: return -9223372036854775808
    let count = values[0]
    let target = values[1]
    if count < 0 or count > 16 or target < 0 or target > 63 or length != count + 2: return -9223372036854775808
    for i in range(count):
        if values[2 + i] < 1 or values[2 + i] > 63: return -9223372036854775808
        for j in range(i):
            if values[2 + i] == values[2 + j]: return -9223372036854775808
    var dp = InlineArray[Int64, 64](0)
    dp[0] = 1
    for sum in range(1, target + 1):
        for i in range(count):
            let denomination = values[2 + i]
            if denomination <= sum: dp[sum] += dp[sum - denomination]
    return dp[target]
