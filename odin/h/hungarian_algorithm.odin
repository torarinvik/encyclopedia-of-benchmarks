package hungarian_algorithm

import "core:c"

store_i32_le :: proc(output: [^]u8, offset: c.size_t, value: i32) {
    bits := u32(value)
    for b: c.size_t = 0; b < 4; b += 1 { output[offset + b] = u8((bits >> (8 * b)) & 0xFF) }
}

@(export)
hungarian_algorithm :: proc "c" (input: [^]i32, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 67 do return -1
    rows, cols := input[0], input[1]
    if rows < 1 || rows > 8 || cols < 1 || cols > 8 || length != 2 + c.size_t(rows * cols) do return -1
    for k: c.size_t = 0; k < c.size_t(rows * cols); k += 1 { if input[2 + k] < 0 || input[2 + k] > 1000 do return -1 }
    n := int(max(rows, cols))
    a: [81]i32
    u, v, p, way: [9]i32
    for i := 0; i < int(rows); i += 1 { for j := 0; j < int(cols); j += 1 { a[i * 9 + j] = input[2 + c.size_t(i * int(cols) + j)] } }
    for i := 1; i <= n; i += 1 {
        p[0] = i; j0 := 0
        minv: [9]i32; used: [9]bool
        for j := 0; j <= n; j += 1 { minv[j] = 2_147_483_647 }
        for {
            used[j0] = true; i0 := p[j0]; delta := i32(2_147_483_647); j1 := 0
            for j := 1; j <= n; j += 1 {
                if !used[j] {
                    cur := a[(i0 - 1) * 9 + j - 1] - u[i0] - v[j]
                    if cur < minv[j] { minv[j] = cur; way[j] = j0 }
                    if minv[j] < delta { delta = minv[j]; j1 = j }
                }
            }
            for j := 0; j <= n; j += 1 { if used[j] { u[p[j]] += delta; v[j] -= delta } else { minv[j] -= delta } }
            j0 = j1
            if p[j0] == 0 { break }
        }
        for { j1 := way[j0]; p[j0] = p[j1]; j0 = j1; if j0 == 0 { break } }
    }
    matched: [9]i32
    for i := 0; i < 9; i += 1 { matched[i] = -1 }
    for j := 1; j <= n; j += 1 { if p[j] != 0 { matched[p[j] - 1] = j - 1 } }
    assignments: [8]i32; total := i32(0)
    for i := 0; i < int(rows); i += 1 {
        j := matched[i]; if j >= 0 && j < cols { assignments[i] = j } else { assignments[i] = -1 }
        if assignments[i] >= 0 { total += input[2 + c.size_t(i*int(cols)+int(assignments[i]))] }
    }
    bytes := c.size_t(4 * (rows + 1))
    if output == nil || capacity < bytes do return -2
    for i := 0; i < int(rows); i += 1 { store_i32_le(output, c.size_t(4 * i), assignments[i]) }
    store_i32_le(output, c.size_t(4 * rows), total)
    return i64(bytes)
}
