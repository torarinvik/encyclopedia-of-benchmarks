"""Bounded deterministic linear-threshold closure with activation rounds."""
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_M = 24

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("deterministic_linear_threshold_spread")
fn deterministic_linear_threshold_spread(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 92: return -1
    let n_value = input[0]
    let m_value = input[1]
    let s_value = input[2]
    if n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > MAX_M or s_value < 0 or s_value > n_value: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    let seed_count = Int(s_value)
    let edge_offset = 3 + seed_count
    let threshold_offset = edge_offset + 3 * m
    if length != c_size_t(threshold_offset + n): return -1
    var seeded = InlineArray[Bool, MAX_N](fill=False)
    var seen = InlineArray[Bool, MAX_N * MAX_N](fill=False)
    var head = InlineArray[Int64, MAX_N](fill=-1)
    var edge_to = InlineArray[Int64, MAX_M](fill=0)
    var edge_weight = InlineArray[Int64, MAX_M](fill=0)
    var edge_next = InlineArray[Int64, MAX_M](fill=-1)
    var incoming = InlineArray[Int64, MAX_N](fill=0)
    var threshold = InlineArray[Int64, MAX_N](fill=0)
    var activation_round = InlineArray[Int64, MAX_N](fill=-1)
    var accumulated = InlineArray[Int64, MAX_N](fill=0)
    for i in range(seed_count):
        let seed = input[3 + i]
        if seed < 0 or seed >= n_value or seeded[Int(seed)]: return -1
        seeded[Int(seed)] = True
    for i in range(m):
        let u = input[edge_offset + 3 * i]
        let v = input[edge_offset + 3 * i + 1]
        let w = input[edge_offset + 3 * i + 2]
        if u < 0 or u >= n_value or v < 0 or v >= n_value or u == v or w < 0 or w > 16: return -1
        let slot = Int(u) * MAX_N + Int(v)
        if seen[slot]: return -1
        seen[slot] = True
        incoming[Int(v)] += w
        if incoming[Int(v)] > 16: return -1
        edge_to[i] = v
        edge_weight[i] = w
        edge_next[i] = head[Int(u)]
        head[Int(u)] = Int64(i)
    for v in range(n):
        threshold[v] = input[threshold_offset + v]
        if threshold[v] < 1 or threshold[v] > 16: return -1
        if seeded[v]: activation_round[v] = 0
    let output_bytes = 8 * (n + 2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2

    var frontier = InlineArray[Int, MAX_N](fill=0)
    var following = InlineArray[Int, MAX_N](fill=0)
    var frontier_count = 0
    for v in range(n):
        if seeded[v]: frontier[frontier_count] = v; frontier_count += 1
    var waves = Int64(0)
    while frontier_count > 0:
        var following_count = 0
        for i in range(frontier_count):
            let source = frontier[i]
            var edge = head[source]
            while edge >= 0:
                let target = Int(edge_to[Int(edge)])
                if activation_round[target] < 0:
                    accumulated[target] += edge_weight[Int(edge)]
                    if accumulated[target] >= threshold[target]:
                        activation_round[target] = waves + 1
                        following[following_count] = target
                        following_count += 1
                edge = edge_next[Int(edge)]
        frontier_count = following_count
        for i in range(following_count): frontier[i] = following[i]
        if following_count > 0: waves += 1
    store_i64_le(output, 0, n_value)
    store_i64_le(output, 8, waves)
    for v in range(n): store_i64_le(output, 8 * (v + 2), activation_round[v])
    return Int64(output_bytes)
