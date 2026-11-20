# Clean-room all-length simple-cycle subset DP; see package RIGHTS.md.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N: Int = 14
const MAX_M: Int = 91
const MAX_STATES: Int = 1 << MAX_N
const MAX_DP_CELLS: Int = MAX_STATES * MAX_N

@export("undirected_simple_cycle_subset_dp_count")
fn undirected_simple_cycle_subset_dp_count(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 185:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > MAX_M:
        return -1
    if m_value > n_value * (n_value - 1) // 2:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 2 * m):
        return -1

    var adjacency = InlineArray[Int, MAX_N * MAX_N](fill=0)
    var neighbors = InlineArray[Int, MAX_N * MAX_N](fill=0)
    var degree = InlineArray[Int, MAX_N](fill=0)
    var previous_u = Int64(-1)
    var previous_v = Int64(-1)
    for edge in range(m):
        let u_value = input[2 + 2 * edge]
        let v_value = input[3 + 2 * edge]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value >= v_value:
            return -1
        if edge != 0 and (u_value < previous_u or (u_value == previous_u and v_value <= previous_v)):
            return -1
        previous_u = u_value
        previous_v = v_value
        let u = Int(u_value)
        let v = Int(v_value)
        adjacency[u * MAX_N + v] = 1
        adjacency[v * MAX_N + u] = 1
        neighbors[u * MAX_N + degree[u]] = v
        degree[u] += 1
        neighbors[v * MAX_N + degree[v]] = u
        degree[v] += 1

    var dp = InlineArray[Int64, MAX_DP_CELLS](fill=0)
    let state_count = 1 << n
    for start in range(n):
        dp[(1 << start) * MAX_N + start] = 1
    var oriented_cycles = Int64(0)
    for mask in range(1, state_count):
        var start = 0
        while (mask & (1 << start)) == 0:
            start += 1
        var cardinality = 0
        for vertex in range(n):
            if (mask & (1 << vertex)) != 0:
                cardinality += 1
        for endpoint in range(n):
            if (mask & (1 << endpoint)) == 0:
                continue
            let ways = dp[mask * MAX_N + endpoint]
            if ways == 0:
                continue
            if cardinality >= 3 and adjacency[endpoint * MAX_N + start] != 0:
                oriented_cycles += ways
            for i in range(degree[endpoint]):
                let next = neighbors[endpoint * MAX_N + i]
                if next > start and (mask & (1 << next)) == 0:
                    dp[(mask | (1 << next)) * MAX_N + next] += ways
    return oriented_cycles // 2
