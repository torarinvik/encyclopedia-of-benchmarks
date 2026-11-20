from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("shortest_path_visiting_all_nodes")
fn shortest_path_visiting_all_nodes(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 93: return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > 10 or m_value < 0 or m_value > 45: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if m > n * (n - 1) // 2 or length != c_size_t(2 + 2 * m): return -1

    var adjacency = InlineArray[Int64, 10](fill=0)
    for edge in range(m):
        let u_value = input[2 + 2 * edge]
        let v_value = input[3 + 2 * edge]
        if u_value < 0 or v_value < 0 or u_value >= n_value or v_value >= n_value or u_value == v_value: return -1
        let u = Int(u_value)
        let v = Int(v_value)
        let u_bit = Int64(1) << v
        let v_bit = Int64(1) << u
        if (adjacency[u] & u_bit) != 0: return -1
        adjacency[u] = adjacency[u] | u_bit
        adjacency[v] = adjacency[v] | v_bit

    var reached: Int64 = 1
    while True:
        let previous = reached
        for vertex in range(n):
            if (reached & (Int64(1) << vertex)) != 0: reached = reached | adjacency[vertex]
        if reached == previous: break
    let full = (Int64(1) << n) - 1
    if reached != full: return -1

    var distance = InlineArray[Int64, 10240](fill=-1)
    var queue = InlineArray[Int64, 10240](fill=0)
    var head = 0
    var tail = 0
    for start in range(n):
        let state = (1 << start) * n + start
        distance[state] = 0
        queue[tail] = state
        tail += 1
    while head < tail:
        let state = Int(queue[head])
        head += 1
        let mask = state // n
        let vertex = state % n
        if mask == Int(full): return distance[state]
        for next in range(n):
            if (adjacency[vertex] & (Int64(1) << next)) == 0: continue
            let next_mask = mask | (1 << next)
            let next_state = next_mask * n + next
            if distance[next_state] >= 0: continue
            distance[next_state] = distance[state] + 1
            queue[tail] = next_state
            tail += 1
    return -1
