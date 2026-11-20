from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 12
comptime MAX_INPUT = 15
comptime WIDTH = MAX_N + 1
comptime CELLS = WIDTH * WIDTH
comptime INF: Int64 = 1000

fn sci_run_cost(kept: Int) -> Int64:
    if kept == 1: return 1
    var value = kept
    var digits = 0
    while value > 0:
        digits += 1
        value /= 10
    return Int64(1 + digits)

fn sci_compute(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length < 2 or length > MAX_INPUT: return -1
    let raw_n = input[0]
    let raw_k = input[1]
    if raw_n < 0 or raw_n > MAX_N or raw_k < 0 or raw_k > raw_n: return -1
    let n = Int(raw_n)
    let budget = Int(raw_k)
    if length != n + 2: return -1
    for i in range(n):
        if input[i + 2] < 0 or input[i + 2] > 25: return -1

    var dp = InlineArray[Int64, CELLS](fill=INF)
    dp[0] = 0
    for start in range(n):
        for used in range(budget + 1):
            let prefix_cost = dp[start * WIDTH + used]
            if prefix_cost == INF: continue
            if used < budget:
                let index = (start + 1) * WIDTH + used + 1
                if prefix_cost < dp[index]: dp[index] = prefix_cost
            var same = 0
            for ending in range(start, n):
                if input[ending + 2] == input[start + 2]: same += 1
                let span = ending - start + 1
                for kept in range(1, same + 1):
                    let deleted = used + span - kept
                    if deleted > budget: continue
                    let candidate = prefix_cost + sci_run_cost(kept)
                    let index = (ending + 1) * WIDTH + deleted
                    if candidate < dp[index]: dp[index] = candidate
    var answer: Int64 = INF
    for deleted in range(budget + 1):
        if dp[n * WIDTH + deleted] < answer: answer = dp[n * WIDTH + deleted]
    return answer

@export("string_compression_ii")
fn string_compression_ii(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    return sci_compute(input, Int(length))
