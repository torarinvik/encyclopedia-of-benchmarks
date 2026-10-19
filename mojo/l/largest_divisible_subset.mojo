from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("largest_divisible_subset")
fn largest_divisible_subset(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if n > 64 or (n > 0 and v == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var a = InlineArray[Int64, 64](fill=0); var dp = InlineArray[Int64, 64](fill=0)
    for i in range(Int(n)):
        if v[i] < 1 or v[i] > 50000: return -1
        a[i] = v[i]
    for i in range(1, Int(n)):
        let x = a[i]; var j = i
        while j > 0 and a[j - 1] > x:
            a[j] = a[j - 1]; j -= 1
        a[j] = x
    var best: Int64 = 0
    for i in range(Int(n)):
        dp[i] = 1
        for j in range(i):
            if a[i] % a[j] == 0 and dp[j] + 1 > dp[i]: dp[i] = dp[j] + 1
        if dp[i] > best: best = dp[i]
    return best
