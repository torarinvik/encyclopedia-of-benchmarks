"""Bounded replay of the Boolean-hypercube edge monotonicity tester."""
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_INPUT_WORDS = 130

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("hypercube_edge_monotonicity_tester")
fn hypercube_edge_monotonicity_tester(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_WORDS:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > 6 or q_value < 1 or q_value > 32:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    let domain = Int(1) << n
    if length != c_size_t(2 + domain + 2 * q):
        return -1
    for vertex in range(domain):
        if input[2 + vertex] != 0 and input[2 + vertex] != 1:
            return -1
    let tape = 2 + domain
    for round in range(q):
        let vertex = input[tape + 2 * round]
        let coordinate = input[tape + 2 * round + 1]
        if vertex < 0 or vertex >= Int64(domain) or coordinate < 0 or coordinate >= n_value:
            return -1

    var accepted = Int64(1)
    var rounds = Int64(0)
    for round in range(q):
        let vertex = Int(input[tape + 2 * round])
        let coordinate = Int(input[tape + 2 * round + 1])
        let bit = Int(1) << coordinate
        let lower = vertex & ~bit
        rounds += 1
        if input[2 + lower] > input[2 + (lower | bit)]:
            accepted = 0
            break

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 24:
        return -2
    store_i64_le(output, 0, accepted)
    store_i64_le(output, 8, rounds)
    store_i64_le(output, 16, 2 * rounds)
    return 24
