from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_N = 9
alias MAX_CELLS = 81
alias MAX_INPUT_LENGTH = 111
alias INF = 1152921504606846976

fn minimum_weight_cycle_floyd_store(
    output: UnsafePointer[UInt8, MutAnyOrigin], value: Int64
):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[byte] = UInt8((bits >> (8 * byte)) & 255)

@export("minimum_weight_cycle_floyd")
fn minimum_weight_cycle_floyd(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 3 or n_value > Int64(MAX_N) or m_value < 0
            or m_value > (n_value * (n_value - 1)) // 2:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 3 * m): return -1

    var edge = InlineArray[Int64, MAX_CELLS]()
    var dist = InlineArray[Int64, MAX_CELLS]()
    for i in range(n):
        for j in range(n):
            if i == j:
                edge[i * MAX_N + j] = 0
            else:
                edge[i * MAX_N + j] = INF
    for e in range(m):
        let offset = 2 + 3 * e
        let u_value = input[offset]
        let v_value = input[offset + 1]
        let weight = input[offset + 2]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value
                or u_value == v_value or weight < 1 or weight > 1000:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        if edge[u * MAX_N + v] != INF: return -1
        edge[u * MAX_N + v] = weight
        edge[v * MAX_N + u] = weight

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8): return -2
    for i in range(n):
        for j in range(n):
            dist[i * MAX_N + j] = edge[i * MAX_N + j]

    var best = INF
    for k in range(n):
        for i in range(k):
            if edge[i * MAX_N + k] == INF: continue
            for j in range(i + 1, k):
                if edge[k * MAX_N + j] == INF or dist[i * MAX_N + j] == INF: continue
                let candidate = edge[i * MAX_N + k] + edge[k * MAX_N + j] + dist[i * MAX_N + j]
                if candidate < best: best = candidate
        for i in range(n):
            if dist[i * MAX_N + k] == INF: continue
            for j in range(n):
                if dist[k * MAX_N + j] == INF: continue
                let candidate = dist[i * MAX_N + k] + dist[k * MAX_N + j]
                if candidate < dist[i * MAX_N + j]: dist[i * MAX_N + j] = candidate
    minimum_weight_cycle_floyd_store(output, -1 if best == INF else best)
    return 8
