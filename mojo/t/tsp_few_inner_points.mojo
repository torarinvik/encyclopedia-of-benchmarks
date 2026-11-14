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

fn tsp_order_cost(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, k: Int,
                  outer: InlineArray[Int, 16], inner: InlineArray[Int, 6]) -> Int64:
    let outside = n - k
    var previous_outer = InlineArray[Int64, 7](fill=TSP_INF)
    var previous_inner = InlineArray[Int64, 7](fill=TSP_INF)
    previous_outer[0] = 0
    for j in range(1, k + 1):
        var best = tsp_safe_add(previous_outer[j - 1], tsp_distance(input, n, outer[0], inner[j - 1]))
        if j > 1:
            best = min(best, tsp_safe_add(previous_inner[j - 1], tsp_distance(input, n, inner[j - 2], inner[j - 1])))
        previous_inner[j] = best
    for i in range(1, outside):
        var current_outer = InlineArray[Int64, 7](fill=TSP_INF)
        var current_inner = InlineArray[Int64, 7](fill=TSP_INF)
        let edge = tsp_distance(input, n, outer[i - 1], outer[i])
        current_outer[0] = tsp_safe_add(previous_outer[0], edge)
        for j in range(1, k + 1):
            current_outer[j] = min(tsp_safe_add(previous_outer[j], edge),
                                   tsp_safe_add(previous_inner[j], tsp_distance(input, n, inner[j - 1], outer[i])))
        for j in range(1, k + 1):
            var best = tsp_safe_add(current_outer[j - 1], tsp_distance(input, n, outer[i], inner[j - 1]))
            if j > 1:
                best = min(best, tsp_safe_add(current_inner[j - 1], tsp_distance(input, n, inner[j - 2], inner[j - 1])))
            current_inner[j] = best
        previous_outer = current_outer
        previous_inner = current_inner
    var best = tsp_safe_add(previous_outer[k], tsp_distance(input, n, outer[outside - 1], outer[0]))
    if k > 0: best = min(best, tsp_safe_add(previous_inner[k], tsp_distance(input, n, inner[k - 1], outer[0])))
    return best

@export("tsp_few_inner_points")
fn tsp_few_inner_points(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
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
    for i in range(1, k):
        let value = inner[i]
        var j = i
        while j > 0 and inner[j - 1] > value:
            inner[j] = inner[j - 1]
            j -= 1
        inner[j] = value
    var best: Int64 = TSP_INF
    while True:
        best = min(best, tsp_order_cost(input, n, k, outer, inner))
        if k < 2: break
        var pivot = k - 2
        while pivot >= 0 and inner[pivot] >= inner[pivot + 1]: pivot -= 1
        if pivot < 0: break
        var j = k - 1
        while inner[j] <= inner[pivot]: j -= 1
        let tmp = inner[pivot]
        inner[pivot] = inner[j]
        inner[j] = tmp
        var left = pivot + 1
        var right = k - 1
        while left < right:
            let value = inner[left]
            inner[left] = inner[right]
            inner[right] = value
            left += 1
            right -= 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var bits = UInt64(best)
    for b in range(8):
        output[b] = UInt8(bits & 255)
        bits >>= 8
    return 8
