from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("unbounded_knapsack")
fn unbounded_knapsack(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 34: return -1
    let count = v[0]; let capacity = v[1]
    if count < 0 or count > 16 or capacity < 0 or capacity > 100 or n != c_size_t(2+2*count): return -1
    for i in range(Int(count)):
        if v[2+i] < 1 or v[2+i] > 100 or v[2+count+i] < 1 or v[2+count+i] > 100: return -1
    if count == 0: return 0
    var dp = InlineArray[Int64, 101](fill=0)
    for c in range(Int(capacity)+1): dp[c] = (c / Int(v[2+count])) * v[2]
    for item in range(1, Int(count)):
        let weight = Int(v[2+Int(count)+item]); let value = v[2+item]
        for c in range(weight, Int(capacity)+1):
            dp[c] = max(dp[c], dp[c-weight]+value)
    return dp[Int(capacity)]
