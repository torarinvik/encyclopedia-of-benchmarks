from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_VERTICES = 8
alias MAX_EDGES = 16
alias MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
alias MAX_OUTPUT_BYTES = 8 * (MAX_VERTICES + 1)

fn chromatic_poly(adjacency: InlineArray[Int64, MAX_VERTICES], n: Int) -> InlineArray[Int64, MAX_VERTICES + 1]:
    var edge_u = n
    var edge_v = n
    for u in range(n):
        if edge_u == n:
            for v in range(u + 1, n):
                if (adjacency[u] & (Int64(1) << v)) != 0:
                    edge_u = u
                    edge_v = v
                    break
    var result = InlineArray[Int64, MAX_VERTICES + 1]()
    for degree in range(MAX_VERTICES + 1):
        result[degree] = 0
    if edge_u == n:
        result[n] = 1
        return result

    var deleted = InlineArray[Int64, MAX_VERTICES]()
    for vertex in range(MAX_VERTICES):
        deleted[vertex] = adjacency[vertex]
    deleted[edge_u] &= ~(Int64(1) << edge_v)
    deleted[edge_v] &= ~(Int64(1) << edge_u)
    let without_edge = chromatic_poly(deleted, n)

    var contracted = InlineArray[Int64, MAX_VERTICES]()
    for vertex in range(MAX_VERTICES):
        contracted[vertex] = 0
    for left in range(n):
        for right in range(left + 1, n):
            if (adjacency[left] & (Int64(1) << right)) != 0 and not (left == edge_u and right == edge_v):
                var new_left = left
                var new_right = right
                if new_left == edge_v:
                    new_left = edge_u
                if new_right == edge_v:
                    new_right = edge_u
                if new_left > edge_v:
                    new_left -= 1
                if new_right > edge_v:
                    new_right -= 1
                if new_left != new_right:
                    contracted[new_left] |= Int64(1) << new_right
                    contracted[new_right] |= Int64(1) << new_left
    let with_edge_contracted = chromatic_poly(contracted, n - 1)
    for degree in range(n + 1):
        result[degree] = without_edge[degree] - with_edge_contracted[degree]
    return result

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("chromatic_polynomial")
fn chromatic_polynomial(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 0 or n_value > MAX_VERTICES or m_value < 0 or m_value > MAX_EDGES:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 2 * m):
        return -1
    var adjacency = InlineArray[Int64, MAX_VERTICES]()
    for vertex in range(MAX_VERTICES):
        adjacency[vertex] = 0
    for edge in range(m):
        let u_value = input[2 + 2 * edge]
        let v_value = input[3 + 2 * edge]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        if (adjacency[u] & (Int64(1) << v)) != 0:
            return -1
        adjacency[u] |= Int64(1) << v
        adjacency[v] |= Int64(1) << u
    let output_bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    let coefficients = chromatic_poly(adjacency, n)
    for degree in range(n + 1):
        store_i64_le(output, 8 * degree, coefficients[degree])
    return Int64(output_bytes)
