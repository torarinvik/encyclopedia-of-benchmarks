package olden_em3d

import "core:c"

MAX_NODES :: 8
MAX_DEGREE :: 4

@(export, link_name="olden_em3d")
olden_em3d :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 2 do return -1
    rn, rd := input[0], input[1]
    if !(rn >= 1.0 && rn <= f64(MAX_NODES)) || rn != f64(int(rn)) do return -1
    if !(rd >= 1.0 && rd <= f64(MAX_DEGREE)) || rd != f64(int(rd)) do return -1
    n, degree := int(rn), int(rd)
    edges := n * degree
    if input_length != c.size_t(2 + 2*n + 4*edges) do return -1
    electric, magnetic: [MAX_NODES]f64
    offset := 2
    for i := 0; i < n; i += 1 {
        if !(input[offset+i] >= 0.0 && input[offset+i] <= 1.0) do return -1
        electric[i] = input[offset+i]
    }
    offset += n
    for i := 0; i < n; i += 1 {
        if !(input[offset+i] >= 0.0 && input[offset+i] <= 1.0) do return -1
        magnetic[i] = input[offset+i]
    }
    offset += n
    e_neighbors := offset; offset += edges
    e_coefficients := offset; offset += edges
    h_neighbors := offset; offset += edges
    h_coefficients := offset
    for i := 0; i < edges; i += 1 {
        en, hn := input[e_neighbors+i], input[h_neighbors+i]
        if !(en >= 0.0 && en < f64(n)) || en != f64(int(en)) || !(hn >= 0.0 && hn < f64(n)) || hn != f64(int(hn)) do return -1
        if !(input[e_coefficients+i] >= 0.0 && input[e_coefficients+i] <= 1.0) || !(input[h_coefficients+i] >= 0.0 && input[h_coefficients+i] <= 1.0) do return -1
        start := (i / degree) * degree
        for j := start; j < i; j += 1 {
            if input[e_neighbors+j] == en || input[h_neighbors+j] == hn do return -1
        }
    }
    if output == nil || output_capacity < c.size_t(2*n) do return -2
    for node := 0; node < n; node += 1 {
        current := electric[node]
        base := node * degree
        for edge := 0; edge < degree; edge += 1 {
            coefficient := base + (edge & ~1)
            current -= input[e_coefficients+coefficient] * magnetic[int(input[e_neighbors+base+edge])]
        }
        electric[node] = current
    }
    for node := 0; node < n; node += 1 {
        current := magnetic[node]
        base := node * degree
        for edge := 0; edge < degree; edge += 1 {
            coefficient := base + (edge & ~1)
            current -= input[h_coefficients+coefficient] * electric[int(input[h_neighbors+base+edge])]
        }
        magnetic[node] = current
    }
    for i := 0; i < n; i += 1 { output[i] = electric[i]; output[n+i] = magnetic[i] }
    return i64(2*n)
}
