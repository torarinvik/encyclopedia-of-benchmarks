from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime STD_MAX_N = 8
comptime STD_MAX_M = 14
comptime STD_MAX_K = 5
comptime STD_MAX_INPUT = 50
comptime STD_MAX_MASKS = 1 << STD_MAX_K
comptime STD_INF: Int64 = 1_000_000_000_000_000_000

fn std_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length < 3 or length > STD_MAX_INPUT: return -1
    let n0 = input[0]
    let m0 = input[1]
    let k0 = input[2]
    if n0 < 1 or n0 > STD_MAX_N or m0 < 0 or m0 > STD_MAX_M or k0 < 1 or k0 > STD_MAX_K or k0 > n0: return -1
    let n = Int(n0)
    let m = Int(m0)
    let k = Int(k0)
    if m > n * (n - 1) // 2 or length != 3 + k + 3 * m: return -1

    var terminal_seen = InlineArray[Bool, STD_MAX_N](fill=False)
    var terminals = InlineArray[Int, STD_MAX_K](fill=0)
    for i in range(k):
        let raw = input[3 + i]
        if raw < 0 or raw >= n0: return -1
        let vertex = Int(raw)
        if terminal_seen[vertex]: return -1
        terminal_seen[vertex] = True
        terminals[i] = vertex

    var present = InlineArray[Bool, STD_MAX_N * STD_MAX_N](fill=False)
    var weights = InlineArray[Int64, STD_MAX_N * STD_MAX_N](fill=0)
    for i in range(m):
        let u0 = input[3 + k + 3 * i]
        let v0 = input[4 + k + 3 * i]
        let w = input[5 + k + 3 * i]
        if u0 < 0 or u0 >= v0 or v0 >= n0 or w < 0 or w > 1000: return -1
        let u = Int(u0)
        let v = Int(v0)
        let edge = u * STD_MAX_N + v
        if present[edge]: return -1
        present[edge] = True
        present[v * STD_MAX_N + u] = True
        weights[edge] = w
        weights[v * STD_MAX_N + u] = w

    var dp = InlineArray[Int64, STD_MAX_MASKS * STD_MAX_N](fill=STD_INF)
    for bit in range(k): dp[(1 << bit) * STD_MAX_N + terminals[bit]] = 0
    let masks = 1 << k
    for mask in range(1, masks):
        if (mask & (mask - 1)) != 0:
            var sub = (mask - 1) & mask
            while sub != 0:
                let other = mask ^ sub
                if sub < other:
                    for v in range(n):
                        let left = dp[sub * STD_MAX_N + v]
                        let right = dp[other * STD_MAX_N + v]
                        if left < STD_INF and right < STD_INF and left + right < dp[mask * STD_MAX_N + v]:
                            dp[mask * STD_MAX_N + v] = left + right
                sub = (sub - 1) & mask
        var used = InlineArray[Bool, STD_MAX_N](fill=False)
        for _ in range(n):
            var chosen = -1
            for v in range(n):
                if not used[v] and (chosen < 0 or dp[mask * STD_MAX_N + v] < dp[mask * STD_MAX_N + chosen]): chosen = v
            if chosen < 0 or dp[mask * STD_MAX_N + chosen] >= STD_INF: break
            used[chosen] = True
            for v in range(n):
                let edge = chosen * STD_MAX_N + v
                if present[edge] and not used[v]:
                    let candidate = dp[mask * STD_MAX_N + chosen] + weights[edge]
                    if candidate < dp[mask * STD_MAX_N + v]: dp[mask * STD_MAX_N + v] = candidate

    var answer = STD_INF
    for v in range(n):
        if dp[(masks - 1) * STD_MAX_N + v] < answer: answer = dp[(masks - 1) * STD_MAX_N + v]
    if answer >= STD_INF: return -2
    answer

@export("steiner_tree_subset_dp")
fn steiner_tree_subset_dp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(STD_MAX_INPUT): return -1
    std_impl(input, Int(length))
