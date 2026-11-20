from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 16
comptime MAX_M = 64
comptime MAX_INPUT = 131
comptime MAX_PARSEABLE = 132
comptime SCALE: Int64 = 1_000_000

@export("hits_fixed_point")
fn hits_fixed_point(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(3) or length > c_size_t(MAX_PARSEABLE):
        return -1
    let n_value = input[0]
    let m_value = input[1]
    let k_value = input[2]
    if n_value < 1 or n_value > Int64(MAX_N): return -1
    if m_value < 0 or m_value > Int64(MAX_M): return -1
    if k_value < 0 or k_value > 32: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    let k = Int(k_value)
    if length != c_size_t(3 + 2 * m) or length > c_size_t(MAX_INPUT): return -1

    var arc_from = InlineArray[Int, MAX_M](fill=0)
    var arc_to = InlineArray[Int, MAX_M](fill=0)
    for arc in range(m):
        let u_value = input[3 + 2 * arc]
        let v_value = input[4 + 2 * arc]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value:
            return -1
        arc_from[arc] = Int(u_value)
        arc_to[arc] = Int(v_value)
        for previous in range(arc):
            if arc_from[previous] == arc_from[arc] and arc_to[previous] == arc_to[arc]: return -1

    var authority = InlineArray[Int64, MAX_N](fill=0)
    var hub = InlineArray[Int64, MAX_N](fill=0)
    for vertex in range(n): hub[vertex] = SCALE

    for iteration in range(k):
        var raw = InlineArray[Int64, MAX_N](fill=0)
        for arc in range(m):
            raw[arc_to[arc]] += hub[arc_from[arc]]
        var authority_total: Int64 = 0
        for vertex in range(n): authority_total += raw[vertex]
        for vertex in range(n):
            if authority_total == 0: authority[vertex] = 0
            else: authority[vertex] = raw[vertex] * SCALE // authority_total

        for vertex in range(n): raw[vertex] = 0
        for arc in range(m):
            raw[arc_from[arc]] += authority[arc_to[arc]]
        var hub_total: Int64 = 0
        for vertex in range(n): hub_total += raw[vertex]
        for vertex in range(n):
            if hub_total == 0: hub[vertex] = 0
            else: hub[vertex] = raw[vertex] * SCALE // hub_total

    var checksum: Int64 = 0
    for vertex in range(n):
        checksum += Int64(vertex + 1) * (authority[vertex] + 65537 * hub[vertex])
    return checksum
