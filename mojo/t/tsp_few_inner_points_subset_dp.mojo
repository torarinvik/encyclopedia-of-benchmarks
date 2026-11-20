from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime TSP_INF = 2305843009213693951

fn tsp_distance(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, a: Int, b: Int) -> Int64:
    let base = 2 + n
    let dx = input[base + 2 * a] - input[base + 2 * b]
    let dy = input[base + 2 * a + 1] - input[base + 2 * b + 1]
    let squared = (dx * dx + dy * dy) * 1000000
    var lo: Int64 = 0
    var hi: Int64 = 3000000
    while lo < hi:
        let mid = lo + (hi - lo + 1) // 2
        if mid * mid <= squared: lo = mid
        else: hi = mid - 1
    let upper = lo + 1
    if upper * upper - squared < squared - lo * lo: return upper
    return lo

fn tsp_safe_add(a: Int64, b: Int64) -> Int64:
    if a >= TSP_INF: return TSP_INF
    return a + b

fn tsp_subset_cost(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, k: Int,
                   outer: InlineArray[Int, 16], inner: InlineArray[Int, 6]) -> Int64:
    let outside = n - k
    let states = 1 << k
    let sentinel = k
    var previous = InlineArray[Int64, 448](fill=TSP_INF)
    previous[sentinel] = 0
    for mask in range(states):
        for last in range(k + 1):
            if last < k and (mask & (1 << last)) == 0: continue
            let prefix = previous[mask * 7 + last]
            if prefix >= TSP_INF: continue
            let vertex = if last == sentinel: outer[0] else: inner[last]
            for next in range(k):
                let bit = 1 << next
                if (mask & bit) != 0: continue
                let next_mask = mask | bit
                let candidate = tsp_safe_add(prefix, tsp_distance(input, n, vertex, inner[next]))
                previous[next_mask * 7 + next] = min(previous[next_mask * 7 + next], candidate)
    for i in range(1, outside):
        var current = InlineArray[Int64, 448](fill=TSP_INF)
        for mask in range(states):
            for last in range(k + 1):
                if last < k and (mask & (1 << last)) == 0: continue
                let prefix = previous[mask * 7 + last]
                if prefix >= TSP_INF: continue
                let vertex = if last == sentinel: outer[i - 1] else: inner[last]
                let candidate = tsp_safe_add(prefix, tsp_distance(input, n, vertex, outer[i]))
                current[mask * 7 + sentinel] = min(current[mask * 7 + sentinel], candidate)
        for mask in range(states):
            for last in range(k + 1):
                if last < k and (mask & (1 << last)) == 0: continue
                let prefix = current[mask * 7 + last]
                if prefix >= TSP_INF: continue
                let vertex = if last == sentinel: outer[i] else: inner[last]
                for next in range(k):
                    let bit = 1 << next
                    if (mask & bit) != 0: continue
                    let next_mask = mask | bit
                    let candidate = tsp_safe_add(prefix, tsp_distance(input, n, vertex, inner[next]))
                    current[next_mask * 7 + next] = min(current[next_mask * 7 + next], candidate)
        previous = current
    let full = states - 1
    var best: Int64 = TSP_INF
    for last in range(k + 1):
        if last < k and (full & (1 << last)) == 0: continue
        let vertex = if last == sentinel: outer[outside - 1] else: inner[last]
        best = min(best, tsp_safe_add(previous[full * 7 + last], tsp_distance(input, n, vertex, outer[0])))
    return best

@export("tsp_few_inner_points_subset_dp")
fn tsp_few_inner_points_subset_dp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 51: return -1
    if input[0] < 3 or input[0] > 16 or input[1] < 0 or input[1] > 6 or input[1] > input[0] - 3: return -1
    let n = Int(input[0])
    let k = Int(input[1])
    if Int(length) != 2 + 3 * n: return -1
    let outside = n - k
    var seen = InlineArray[Bool, 16](fill=False)
    var outer = InlineArray[Int, 16](fill=0)
    var inner = InlineArray[Int, 6](fill=0)
    for i in range(n):
        let vertex = input[2 + i]
        if vertex < 0 or vertex >= Int64(n): return -1
        if seen[Int(vertex)]: return -1
        seen[Int(vertex)] = True
        if i < outside: outer[i] = Int(vertex)
        else: inner[i - outside] = Int(vertex)
    let base = 2 + n
    for i in range(n):
        let x = input[base + 2 * i]
        let y = input[base + 2 * i + 1]
        if x < -1000 or x > 1000 or y < -1000 or y > 1000: return -1
        for j in range(i):
            if x == input[base + 2 * j] and y == input[base + 2 * j + 1]: return -1
    let best = tsp_subset_cost(input, n, k, outer, inner)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var bits = UInt64(best)
    for b in range(8):
        output[b] = UInt8(bits & 255)
        bits >>= 8
    return 8
