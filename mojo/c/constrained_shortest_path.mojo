from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("constrained_shortest_path")
fn constrained_shortest_path(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5: return -2
    let n = input[0]
    let m = input[1]
    let start = input[2]
    let target = input[3]
    let limit = input[4]
    if n < 1 or n > 16 or m < 0 or m > 64 or limit < 0 or limit > 32 or length != 5 + 4 * m or start < 0 or start >= n or target < 0 or target >= n: return -2
    for e in range(m):
        let p = 5 + 4 * e
        if input[p] < 0 or input[p] >= n or input[p + 1] < 0 or input[p + 1] >= n or input[p + 2] < 0 or input[p + 2] > 1000 or input[p + 3] < 1 or input[p + 3] > 32: return -2
    var dp = InlineArray[Int64, 528](0)
    for i in range(528): dp[i] = 9223372036854775807
    dp[start] = 0
    for r in range(limit + 1):
        for u in range(n):
            let current = dp[r * 16 + u]
            if current == 9223372036854775807: continue
            for e in range(m):
                let p = 5 + 4 * e
                if input[p] != u: continue
                let resource = input[p + 3]
                if r + resource <= limit:
                    let v = input[p + 1]
                    let candidate = current + input[p + 2]
                    let index = (r + resource) * 16 + v
                    if candidate < dp[index]: dp[index] = candidate
    var answer: Int64 = 9223372036854775807
    for r in range(limit + 1):
        if dp[r * 16 + target] < answer: answer = dp[r * 16 + target]
    return -1 if answer == 9223372036854775807 else answer
