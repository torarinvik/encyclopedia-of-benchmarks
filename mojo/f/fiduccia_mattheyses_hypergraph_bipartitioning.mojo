from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime FM_MAX_N = 8
comptime FM_MAX_M = 12
comptime FM_MAX_INPUT = 111
comptime FM_MAX_PARSEABLE = 112
comptime FM_BUCKET_COUNT = 25

fn fm_cut(mask: Int64, edge_count: Int, degrees: InlineArray[Int, FM_MAX_M],
          vertices: InlineArray[Int, FM_MAX_M * FM_MAX_N]) -> Int:
    var cut = 0
    for edge in range(edge_count):
        var in_a = False
        var in_b = False
        for slot in range(degrees[edge]):
            let vertex = vertices[edge * FM_MAX_N + slot]
            if ((mask >> vertex) & 1) != 0: in_a = True
            else: in_b = True
        if in_a and in_b: cut += 1
    return cut

fn fm_gain(mask: Int64, vertex: Int, edge_count: Int,
           degrees: InlineArray[Int, FM_MAX_M],
           vertices: InlineArray[Int, FM_MAX_M * FM_MAX_N]) -> Int:
    var gain = 0
    let vertex_bit = Int64(1) << vertex
    let in_a_now = (mask & vertex_bit) != 0
    for edge in range(edge_count):
        var contains_vertex = False
        var other_a = False
        var other_b = False
        for slot in range(degrees[edge]):
            let member = vertices[edge * FM_MAX_N + slot]
            if member == vertex: contains_vertex = True
            elif ((mask >> member) & 1) != 0: other_a = True
            else: other_b = True
        if contains_vertex:
            let before_cut = (other_a or in_a_now) and (other_b or not in_a_now)
            let after_cut = if in_a_now: other_a else: other_b
            if before_cut: gain += 1
            if after_cut: gain -= 1
    return gain

fn dsl_fm_execute(values: InlineArray[Int64, FM_MAX_PARSEABLE], length: Int) -> Int64:
    if length < 3 or length > FM_MAX_PARSEABLE: return -1
    let n_value = values[0]
    let m_value = values[1]
    var mask = values[2]
    if n_value < 4 or n_value > FM_MAX_N or (n_value % 2) != 0: return -1
    if m_value < 0 or m_value > FM_MAX_M: return -1
    let n = Int(n_value)
    let edge_count = Int(m_value)
    if mask < 0 or mask >= (Int64(1) << n): return -1
    var initial_a = 0
    for vertex in range(n):
        if ((mask >> vertex) & 1) != 0: initial_a += 1
    if initial_a != n // 2: return -1

    var degrees = InlineArray[Int, FM_MAX_M](fill=0)
    var vertices = InlineArray[Int, FM_MAX_M * FM_MAX_N](fill=0)
    var position = 3
    for edge in range(edge_count):
        if position >= length: return -1
        let degree_value = values[position]
        if degree_value < 2 or degree_value > n: return -1
        let degree = Int(degree_value)
        if position + 1 + degree > length: return -1
        var previous_vertex = -1
        for slot in range(degree):
            let vertex_value = values[position + 1 + slot]
            if vertex_value < 0 or vertex_value >= n or vertex_value <= previous_vertex: return -1
            vertices[edge * FM_MAX_N + slot] = Int(vertex_value)
            previous_vertex = Int(vertex_value)
        degrees[edge] = degree
        position += 1 + degree
    if position != length or length > FM_MAX_INPUT: return -1

    var current_cut = fm_cut(mask, edge_count, degrees, vertices)
    var a_size = initial_a
    var pass_count = 0
    while pass_count <= edge_count:
        let pass_start_mask = mask
        let pass_start_cut = current_cut
        var best_prefix_mask = mask
        var best_prefix_cut = current_cut
        var working_a_size = a_size
        var locked = InlineArray[Bool, FM_MAX_N](fill=False)
        var moves = 0
        while moves < n:
            var bucket_best = InlineArray[Int, FM_BUCKET_COUNT](fill=-1)
            var bucket_balance = InlineArray[Int, FM_BUCKET_COUNT](fill=0)
            for vertex in range(n):
                if not locked[vertex]:
                    let bit = Int64(1) << vertex
                    let in_a = (mask & bit) != 0
                    let resulting_a = if in_a: working_a_size - 1 else: working_a_size + 1
                    if resulting_a >= n // 2 - 1 and resulting_a <= n // 2 + 1:
                        let gain = fm_gain(mask, vertex, edge_count, degrees, vertices)
                        let bucket_index = gain + FM_MAX_M
                        let balance = if 2 * resulting_a - n < 0: n - 2 * resulting_a else: 2 * resulting_a - n
                        if bucket_best[bucket_index] < 0 or balance < bucket_balance[bucket_index] or
                           (balance == bucket_balance[bucket_index] and vertex < bucket_best[bucket_index]):
                            bucket_best[bucket_index] = vertex
                            bucket_balance[bucket_index] = balance

            var selected = n
            var selected_gain = 0
            var bucket = FM_BUCKET_COUNT
            while bucket > 0:
                bucket -= 1
                if bucket_best[bucket] >= 0:
                    selected = bucket_best[bucket]
                    selected_gain = bucket - FM_MAX_M
                    break
            if selected == n: break

            let bit = Int64(1) << selected
            if (mask & bit) != 0:
                mask -= bit
                working_a_size -= 1
            else:
                mask += bit
                working_a_size += 1
            locked[selected] = True
            current_cut -= selected_gain
            moves += 1
            if current_cut < best_prefix_cut:
                best_prefix_cut = current_cut
                best_prefix_mask = mask

        if best_prefix_cut < pass_start_cut:
            mask = best_prefix_mask
            current_cut = best_prefix_cut
            a_size = 0
            for vertex in range(n):
                if ((mask >> vertex) & 1) != 0: a_size += 1
            pass_count += 1
        else:
            mask = pass_start_mask
            current_cut = pass_start_cut
            break
    return Int64(current_cut * 256) + mask

@export("fiduccia_mattheyses_hypergraph_bipartitioning")
fn fiduccia_mattheyses_hypergraph_bipartitioning(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(3) or length > c_size_t(FM_MAX_PARSEABLE):
        return -1
    let input_length = Int(length)
    var values = InlineArray[Int64, FM_MAX_PARSEABLE](fill=0)
    for index in range(input_length): values[index] = input[index]
    return dsl_fm_execute(values, input_length)
