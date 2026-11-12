from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime KOBST_MAX_N = 64
comptime KOBST_MAX_INPUT = 65
comptime KOBST_MAX_FREQUENCY: Int64 = 1_000_000

@export("knuth_optimized_optimal_binary_search_tree")
fn knuth_optimized_optimal_binary_search_tree(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > KOBST_MAX_INPUT: return -1
    let count_value = v[0]
    if count_value < 1 or count_value > KOBST_MAX_N or Int(n) != Int(count_value) + 1: return -1
    let count = Int(count_value)
    var prefix = InlineArray[Int64, 65](fill=0)
    var dp = InlineArray[Int64, 4096](fill=0)
    var opt = InlineArray[Int32, 4096](fill=0)
    for i in range(count):
        let f = v[i + 1]
        if f < 0 or f > KOBST_MAX_FREQUENCY: return -1
        prefix[i + 1] = prefix[i] + f
        dp[i * 64 + i] = f
        opt[i * 64 + i] = Int32(i)
    for width in range(2, count + 1):
        for left in range(count - width + 1):
            let right = left + width - 1
            let first = Int(opt[left * 64 + right - 1])
            let last = Int(opt[(left + 1) * 64 + right])
            let total = prefix[right + 1] - prefix[left]
            var best: Int64 = 9223372036854775807
            var best_root = first
            for root in range(first, last + 1):
                var value = total
                if root > left: value += dp[left * 64 + root - 1]
                if root < right: value += dp[(root + 1) * 64 + right]
                if value < best: best = value; best_root = root
            dp[left * 64 + right] = best
            opt[left * 64 + right] = Int32(best_root)
    return dp[count - 1]
