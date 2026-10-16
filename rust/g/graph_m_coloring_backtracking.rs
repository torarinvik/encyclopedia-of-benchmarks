const MAX_VERTICES: usize = 12;

fn assign_colors(input: &[i64], count: usize, max_colors: usize,
                 vertex: usize, colors: &mut [i64; MAX_VERTICES]) -> bool {
    if vertex == count { return true; }
    for color in 0..max_colors {
        let safe = (0..count).all(|neighbor|
            input[2 + vertex * count + neighbor] != 1 || colors[neighbor] != color as i64);
        if !safe { continue; }
        colors[vertex] = color as i64;
        if assign_colors(input, count, max_colors, vertex + 1, colors) { return true; }
        colors[vertex] = -1;
    }
    false
}

fn put_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn graph_m_coloring_backtracking(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let max_colors_value = values[1];
    if n_value < 0 || n_value > MAX_VERTICES as i64 ||
        max_colors_value < 0 || max_colors_value > MAX_VERTICES as i64 { return -1; }
    let n = n_value as usize;
    let max_colors = max_colors_value as usize;
    if length != 2 + n * n { return -1; }
    for row in 0..n {
        if values[2 + row * n + row] != 0 { return -1; }
        for column in 0..n {
            let cell = values[2 + row * n + column];
            if (cell != 0 && cell != 1) || cell != values[2 + column * n + row] { return -1; }
        }
    }
    let mut colors = [-1i64; MAX_VERTICES];
    if !assign_colors(values, n, max_colors, 0, &mut colors) { return 0; }
    let required = n * 8;
    if required == 0 { return 0; }
    if output.is_null() || capacity < required { return -2; }
    let output = std::slice::from_raw_parts_mut(output, required);
    for vertex in 0..n { put_i64(output, vertex * 8, colors[vertex]); }
    required as i64
}
