module hungarian_algorithm

fn store_i32_le(output &u8, offset int, value i32) {
    bits := u32(value)
    for b in 0 .. 4 { unsafe { output[offset + b] = u8((bits >> (8 * b)) & 255) } }
}

@[export: 'hungarian_algorithm']
pub fn hungarian_algorithm(input &i32, length usize, output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 67 { return -1 }
    rows := unsafe { input[0] }; cols := unsafe { input[1] }
    if rows < 1 || rows > 8 || cols < 1 || cols > 8 || length != usize(2 + rows * cols) { return -1 }
    for k in 0 .. int(rows * cols) { if unsafe { input[2 + k] < 0 || input[2 + k] > 1000 } { return -1 } }
    n := int(max(rows, cols))
    mut a := [81]i32{}
    mut u := [9]i32{}; mut v := [9]i32{}; mut p := [9]i32{}; mut way := [9]i32{}
    for i in 0 .. int(rows) { for j in 0 .. int(cols) { a[i * 9 + j] = unsafe { input[2 + i * int(cols) + j] } } }
    for i in 1 .. n + 1 {
        p[0] = i32(i); mut j0 := 0
        mut minv := [9]i32{}; mut used := [9]bool{}
        for j in 0 .. n + 1 { minv[j] = 2147483647 }
        for {
            used[j0] = true; i0 := int(p[j0]); mut delta := i32(2147483647); mut j1 := 0
            for j in 1 .. n + 1 {
                if !used[j] {
                    cur := a[(i0 - 1) * 9 + j - 1] - u[i0] - v[j]
                    if cur < minv[j] { minv[j] = cur; way[j] = i32(j0) }
                    if minv[j] < delta { delta = minv[j]; j1 = j }
                }
            }
            for j in 0 .. n + 1 { if used[j] { u[int(p[j])] += delta; v[j] -= delta } else { minv[j] -= delta } }
            j0 = j1
            if p[j0] == 0 { break }
        }
        for { j1 := int(way[j0]); p[j0] = p[j1]; j0 = j1; if j0 == 0 { break } }
    }
    mut matched := [9]i32{}
    for i in 0 .. 9 { matched[i] = -1 }
    for j in 1 .. n + 1 { if p[j] != 0 { matched[int(p[j] - 1)] = i32(j - 1) } }
    mut assignments := [8]i32{}; mut total := i32(0)
    for i in 0 .. int(rows) {
        j := matched[i]
        assignments[i] = if j >= 0 && j < cols { j } else { -1 }
        if assignments[i] >= 0 { total += unsafe { input[2 + i * int(cols) + int(assignments[i])] } }
    }
    bytes := 4 * (int(rows) + 1)
    if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
    for i in 0 .. int(rows) { store_i32_le(output, 4 * i, assignments[i]) }
    store_i32_le(output, 4 * int(rows), total)
    return i64(bytes)
}
