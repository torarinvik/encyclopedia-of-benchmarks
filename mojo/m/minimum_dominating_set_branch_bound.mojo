from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 12
comptime MAX_INPUT = 135

fn mds_popcount(bits_input: UInt64) -> Int:
    var bits = bits_input
    var count = 0
    while bits != 0:
        bits = bits & (bits - UInt64(1))
        count += 1
    return count

fn mds_search(closed: InlineArray[UInt64, MAX_N], n: Int, full: UInt64,
              covered: UInt64, chosen: Int, inout best: Int):
    if chosen >= best: return
    if covered == full:
        best = chosen
        return
    let uncovered = full & (~covered)
    let uncovered_count = mds_popcount(uncovered)
    var maximum_gain = 0
    for v in range(n): maximum_gain = max(maximum_gain, mds_popcount(closed[v] & uncovered))
    let lower_bound = (uncovered_count + maximum_gain - 1) // maximum_gain
    if chosen + lower_bound >= best: return

    var branch = -1
    var branch_degree = MAX_N + 1
    for v in range(n):
        if (uncovered & (UInt64(1) << v)) != 0:
            let degree = mds_popcount(closed[v])
            if degree < branch_degree: branch = v; branch_degree = degree
    var candidates = InlineArray[Int, MAX_N](fill=0)
    var gains = InlineArray[Int, MAX_N](fill=0)
    var count = 0
    for v in range(n):
        if (closed[branch] & (UInt64(1) << v)) == 0: continue
        let gain = mds_popcount(closed[v] & uncovered)
        var pos = count
        while pos > 0 and (gain > gains[pos - 1] or (gain == gains[pos - 1] and v < candidates[pos - 1])):
            gains[pos] = gains[pos - 1]; candidates[pos] = candidates[pos - 1]; pos -= 1
        gains[pos] = gain; candidates[pos] = v; count += 1
    for i in range(count):
        let v = candidates[i]
        mds_search(closed, n, full, covered | closed[v], chosen + 1, best)

@export("minimum_dominating_set_branch_bound")
fn minimum_dominating_set_branch_bound(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                       length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let n64 = input[0]; let m64 = input[1]
    if n64 < 1 or n64 > MAX_N: return -1
    let n = Int(n64)
    if m64 < 0 or m64 > n64 * (n64 - 1) // 2 or length != c_size_t(2 + 2 * m64): return -1
    var adjacency = InlineArray[UInt64, MAX_N](fill=UInt64(0))
    for e in range(Int(m64)):
        let u64 = input[2 + 2 * e]; let v64 = input[3 + 2 * e]
        if u64 < 0 or v64 < 0 or u64 >= n64 or v64 >= n64 or u64 == v64: return -1
        let u = Int(u64); let v = Int(v64); let bit = UInt64(1) << v
        if (adjacency[u] & bit) != 0: return -1
        adjacency[u] = adjacency[u] | bit
        adjacency[v] = adjacency[v] | (UInt64(1) << u)
    var closed = InlineArray[UInt64, MAX_N](fill=UInt64(0))
    for v in range(n): closed[v] = adjacency[v] | (UInt64(1) << v)
    let full = (UInt64(1) << n) - UInt64(1)
    var covered = UInt64(0); var greedy = 0
    while covered != full:
        var vertex = 0; var best_gain = -1
        for v in range(n):
            let gain = mds_popcount(closed[v] & (~covered))
            if gain > best_gain: vertex = v; best_gain = gain
        covered = covered | closed[vertex]; greedy += 1
    var best = greedy
    mds_search(closed, n, full, UInt64(0), 0, best)
    return Int64(best)
