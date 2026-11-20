from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_N = 8
alias MATRIX_WIDTH = 17
alias MAX_INPUT_LENGTH = 115
alias MODULUS: Int64 = 1_000_000_007

fn rw_norm(value_input: Int64) -> Int64:
    var value = value_input % MODULUS
    if value < 0: value += MODULUS
    return value

fn rw_power(base_input: Int64, exponent_input: Int64) -> Int64:
    var base = rw_norm(base_input)
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result

fn rw_reaches_all(graph: InlineArray[Bool, 64], n: Int, reverse: Bool) -> Bool:
    var seen = InlineArray[Bool, 8](fill=False)
    var queue = InlineArray[Int, 8](fill=0)
    var head = 0
    var tail = 1
    seen[0] = True
    queue[0] = 0
    while head < tail:
        let current = queue[head]
        head += 1
        for to in range(n):
            let has_edge = graph[to * MAX_N + current] if reverse else graph[current * MAX_N + to]
            if has_edge and not seen[to]:
                seen[to] = True
                queue[tail] = to
                tail += 1
    return tail == n

fn rw_eliminate(inout matrix: InlineArray[Int64, 136], size: Int, rhs_count: Int) -> Bool:
    let width = size + rhs_count
    for column in range(size):
        var pivot = column
        while pivot < size and rw_norm(matrix[pivot * MATRIX_WIDTH + column]) == 0: pivot += 1
        if pivot == size: return False
        for j in range(width):
            let temporary = matrix[column * MATRIX_WIDTH + j]
            matrix[column * MATRIX_WIDTH + j] = matrix[pivot * MATRIX_WIDTH + j]
            matrix[pivot * MATRIX_WIDTH + j] = temporary
        let inverse = rw_power(matrix[column * MATRIX_WIDTH + column], MODULUS - 2)
        for j in range(width): matrix[column * MATRIX_WIDTH + j] = matrix[column * MATRIX_WIDTH + j] * inverse % MODULUS
        for row in range(size):
            if row == column: continue
            let factor = rw_norm(matrix[row * MATRIX_WIDTH + column])
            if factor != 0:
                for j in range(width):
                    matrix[row * MATRIX_WIDTH + j] = rw_norm(matrix[row * MATRIX_WIDTH + j]
                        - factor * matrix[column * MATRIX_WIDTH + j] % MODULUS)
    return True

fn rw_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("all_pairs_directed_random_walk_hitting_times")
fn all_pairs_directed_random_walk_hitting_times(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2
            or length > c_size_t(MAX_INPUT_LENGTH): return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 3 or n_value > MAX_N: return -1
    if m_value < 0 or m_value > n_value * (n_value - 1): return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 2 * m): return -1

    var graph = InlineArray[Bool, 64](fill=False)
    var degree = InlineArray[Int, 8](fill=0)
    for edge in range(m):
        let u_value = input[2 + 2 * edge]
        let v_value = input[3 + 2 * edge]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value
                or u_value == v_value: return -1
        let u = Int(u_value)
        let v = Int(v_value)
        if graph[u * MAX_N + v]: return -1
        graph[u * MAX_N + v] = True
        degree[u] += 1
    for vertex in range(n):
        if degree[vertex] == 0: return -1
    if not rw_reaches_all(graph, n, False) or not rw_reaches_all(graph, n, True): return -1
    let output_bytes = 8 * n * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2

    var stationary = InlineArray[Int64, 136](fill=0)
    for destination in range(n - 1):
        for source in range(n):
            let transition = rw_power(Int64(degree[source]), MODULUS - 2) if graph[source * MAX_N + destination] else 0
            stationary[destination * MATRIX_WIDTH + source] = rw_norm(transition - (1 if source == destination else 0))
    for source in range(n): stationary[(n - 1) * MATRIX_WIDTH + source] = 1
    stationary[(n - 1) * MATRIX_WIDTH + n] = 1
    if not rw_eliminate(stationary, n, 1): return -1
    var reciprocal = InlineArray[Int64, 8](fill=0)
    for vertex in range(n):
        let pi = rw_norm(stationary[vertex * MATRIX_WIDTH + n])
        if pi == 0: return -1
        reciprocal[vertex] = rw_power(pi, MODULUS - 2)

    var reduced = InlineArray[Int64, 136](fill=0)
    for row in range(n - 1):
        for column in range(n - 1):
            let transition = rw_power(Int64(degree[row]), MODULUS - 2) if graph[row * MAX_N + column] else 0
            reduced[row * MATRIX_WIDTH + column] = rw_norm((1 if row == column else 0) - transition)
        for target in range(n):
            reduced[row * MATRIX_WIDTH + n - 1 + target] = rw_norm(1 - (reciprocal[target] if row == target else 0))
    if not rw_eliminate(reduced, n - 1, n): return -1
    var y = InlineArray[Int64, 64](fill=0)
    for row in range(n - 1):
        for target in range(n): y[row * MAX_N + target] = rw_norm(reduced[row * MATRIX_WIDTH + n - 1 + target])
    for source in range(n):
        for target in range(n):
            rw_store(output, 8 * (source * n + target), rw_norm(y[source * MAX_N + target] - y[target * MAX_N + target]))
    return Int64(output_bytes)
