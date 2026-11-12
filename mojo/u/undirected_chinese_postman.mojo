from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 8
alias MAX_M = 12
alias INF = 1_000_000_000

@export("undirected_chinese_postman")
fn undirected_chinese_postman(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 38:
        return -1
    if input[0] < 1 or input[0] > Int64(MAX_N) or input[1] < 0 or input[1] > Int64(MAX_M):
        return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if length != 2 + 3 * m:
        return -1
    if n == 1:
        return 0 if m == 0 else -1
    if m < n - 1:
        return -1
    var distance = InlineArray[Int64, MAX_N * MAX_N]()
    var seen = InlineArray[Bool, MAX_N * MAX_N]()
    var degree = InlineArray[Int, MAX_N]()
    for u in range(n):
        for v in range(n):
            distance[u * MAX_N + v] = 0 if u == v else INF
    var total_weight: Int64 = 0
    for edge in range(m):
        let u_value = input[2 + 3 * edge]
        let v_value = input[3 + 3 * edge]
        let weight = input[4 + 3 * edge]
        if u_value < 0 or u_value >= Int64(n) or v_value < 0 or v_value >= Int64(n) or u_value == v_value or weight < 1 or weight > 1000:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        if seen[u * MAX_N + v]:
            return -1
        seen[u * MAX_N + v] = True
        seen[v * MAX_N + u] = True
        distance[u * MAX_N + v] = weight
        distance[v * MAX_N + u] = weight
        degree[u] += 1
        degree[v] += 1
        total_weight += weight
    for middle in range(n):
        for source in range(n):
            for target in range(n):
                let candidate = distance[source * MAX_N + middle] + distance[middle * MAX_N + target]
                if candidate < distance[source * MAX_N + target]:
                    distance[source * MAX_N + target] = candidate
    for vertex in range(n):
        if distance[vertex] >= INF:
            return -1
    var odd = InlineArray[Int, MAX_N]()
    var odd_count = 0
    for vertex in range(n):
        if degree[vertex] % 2 != 0:
            odd[odd_count] = vertex
            odd_count += 1
    let state_count = 1 << odd_count
    var pairing = InlineArray[Int64, 1 << MAX_N]()
    for mask in range(state_count):
        pairing[mask] = INF
    pairing[0] = 0
    for mask in range(1, state_count):
        var first = 0
        while (mask & (1 << first)) == 0:
            first += 1
        let first_bit = 1 << first
        for partner in range(first + 1, odd_count):
            let partner_bit = 1 << partner
            if (mask & partner_bit) == 0:
                continue
            let remaining = mask ^ first_bit ^ partner_bit
            let candidate = distance[odd[first] * MAX_N + odd[partner]] + pairing[remaining]
            if candidate < pairing[mask]:
                pairing[mask] = candidate
    return total_weight + pairing[state_count - 1]
