# Clean-room degree-oriented simple C4 counter; see package RIGHTS.md.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N: Int = 16
const MAX_M: Int = 64

@export("undirected_four_cycle_count_degree_order")
fn undirected_four_cycle_count_degree_order(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 131:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > MAX_M:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 2 * m):
        return -1

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
        neighbors[u * MAX_N + degree[u]] = v
        degree[u] += 1
        neighbors[v * MAX_N + degree[v]] = u
        degree[v] += 1

    var order = InlineArray[Int, MAX_N](fill=0)
    var rank = InlineArray[Int, MAX_N](fill=0)
    for i in range(n):
        order[i] = i
    for i in range(1, n):
        let key = order[i]
        var j = i
        while j > 0:
            let prior = order[j - 1]
            if degree[prior] < degree[key] or (degree[prior] == degree[key] and prior < key):
                break
            order[j] = prior
            j -= 1
        order[j] = key
    for i in range(n):
        rank[order[i]] = i

    var count = InlineArray[Int64, MAX_N](fill=0)
    var total = Int64(0)
    for position in range(n):
        let pivot = order[position]
        for bi in range(degree[pivot]):
            let middle = neighbors[pivot * MAX_N + bi]
            if rank[middle] >= position:
                continue
            for ci in range(degree[middle]):
                let opposite = neighbors[middle * MAX_N + ci]
                if rank[opposite] < position:
                    total += count[opposite]
                    count[opposite] += 1
        for vertex in range(n):
            count[vertex] = 0
    return total
