from std.collections import InlineArray

@export("fibonacci_dp")
fn fibonacci_dp(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 46: return -1
    var table = InlineArray[Int64, 47](0)
    table[0] = 0
    table[1] = 1
    for i in range(2, n + 1): table[i] = table[i - 1] + table[i - 2]
    return table[n]
