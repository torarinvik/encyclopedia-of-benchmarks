package transitive_closure_reflexive_matrix

import "core:c"

Max_Vertices :: 32
Max_Edges :: Max_Vertices * (Max_Vertices - 1)
Max_Input_Length :: 2 + 2 * Max_Edges
Max_Cells :: Max_Vertices * Max_Vertices

put_i64_le :: proc(value: i64, output: [^]u8, offset: usize) {
    bits := transmute(u64)value
    for byte: usize = 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
transitive_closure_reflexive_matrix :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > Max_Input_Length do return -1
    n_value := input[0]
    if n_value < 1 || n_value > Max_Vertices do return -1
    n := usize(n_value)
    m_value := input[1]
    if m_value < 0 || m_value > i64(n * (n - 1)) do return -1
    m := usize(m_value)
    if length != 2 + 2 * m do return -1

    reach: [Max_Cells]i64
    for index: usize = 0; index < Max_Cells; index += 1 { reach[index] = 0 }
    for i: usize = 0; i < n; i += 1 { reach[i * n + i] = 1 }
    for edge: usize = 0; edge < m; edge += 1 {
        from_value, to_value := input[2 + 2 * edge], input[3 + 2 * edge]
        if from_value < 0 || from_value >= i64(n) || to_value < 0 || to_value >= i64(n) || from_value == to_value do return -1
        from, to := usize(from_value), usize(to_value)
        if reach[from * n + to] != 0 do return -1
        reach[from * n + to] = 1
    }
    for k: usize = 0; k < n; k += 1 {
        for i: usize = 0; i < n; i += 1 {
            if reach[i * n + k] == 1 {
                for j: usize = 0; j < n; j += 1 {
                    if reach[k * n + j] == 1 { reach[i * n + j] = 1 }
                }
            }
        }
    }
    output_bytes := n * n * 8
    if output == nil || capacity < output_bytes do return -2
    for index: usize = 0; index < n * n; index += 1 { put_i64_le(reach[index], output, index * 8) }
    return i64(output_bytes)
}
