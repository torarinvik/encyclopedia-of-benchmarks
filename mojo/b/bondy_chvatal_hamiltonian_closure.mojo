from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_VERTICES = 8
const MAX_EDGES = 28
const MAX_INPUT_WORDS = 59
const MAX_OUTPUT_WORDS = 10

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits = bits >> 8

@export("bondy_chvatal_hamiltonian_closure")
fn bondy_chvatal_hamiltonian_closure(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_WORDS):
        return -1
    let n_word = input[0]
    let m_word = input[1]
    if n_word < 3 or n_word > MAX_VERTICES or m_word < 0 or m_word > MAX_EDGES:
        return -1
    let n = Int(n_word)
    let m = Int(m_word)
    if m > n * (n - 1) // 2 or length != c_size_t(2 + 2 * m):
        return -1

    var adjacency = InlineArray[Bool, MAX_VERTICES * MAX_VERTICES](fill=False)
    for edge in range(m):
        let u_word = input[2 + 2 * edge]
        let v_word = input[3 + 2 * edge]
        if u_word < 0 or u_word >= n_word or v_word < 0 or v_word >= n_word or u_word == v_word:
            return -1
        let u = Int(u_word)
        let v = Int(v_word)
        if adjacency[u * MAX_VERTICES + v]:
            return -1
        adjacency[u * MAX_VERTICES + v] = True
        adjacency[v * MAX_VERTICES + u] = True

    var added = 0
    while True:
        var degree = InlineArray[Int, MAX_VERTICES](fill=0)
        for u in range(n):
            for v in range(n):
                if adjacency[u * MAX_VERTICES + v]:
                    degree[u] += 1
        var chosen_u = n
        var chosen_v = n
        for u in range(n):
            if chosen_u < n:
                break
            for v in range(u + 1, n):
                if not adjacency[u * MAX_VERTICES + v] and degree[u] + degree[v] >= n:
                    chosen_u = u
                    chosen_v = v
                    break
        if chosen_u == n:
            break
        adjacency[chosen_u * MAX_VERTICES + chosen_v] = True
        adjacency[chosen_v * MAX_VERTICES + chosen_u] = True
        added += 1

    var staged = InlineArray[Int64, MAX_OUTPUT_WORDS](fill=0)
    let full_mask = (1 << n) - 1
    var complete = True
    for u in range(n):
        var row = 0
        for v in range(n):
            if adjacency[u * MAX_VERTICES + v]:
                row |= 1 << v
        staged[2 + u] = Int64(row)
        if row != (full_mask ^ (1 << u)):
            complete = False
    staged[0] = 1 if complete else 0
    staged[1] = Int64(added)

    let output_bytes = (2 + n) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for word in range(2 + n):
        store_i64_le(output, word * 8, staged[word])
    return Int64(output_bytes)
