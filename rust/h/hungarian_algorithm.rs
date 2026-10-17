fn store_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for b in 0..4 { unsafe { *output.add(offset + b) = (bits >> (8 * b)) as u8; } }
}
#[no_mangle]
pub unsafe extern "C" fn hungarian_algorithm(input: *const i32, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 67 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (rows, cols) = (values[0], values[1]);
    if !(1..=8).contains(&rows) || !(1..=8).contains(&cols) || length != 2 + (rows * cols) as usize { return -1; }
    for &cost in &values[2..] { if !(0..=1000).contains(&cost) { return -1; } }
    let n = rows.max(cols) as usize;
    let mut a = [0i32; 81]; let mut u = [0i32; 9]; let mut v = [0i32; 9]; let mut p = [0i32; 9]; let mut way = [0i32; 9];
    for i in 0..rows as usize { for j in 0..cols as usize { a[i * 9 + j] = values[2 + i * cols as usize + j]; } }
    for i in 1..=n {
        p[0] = i as i32; let mut j0 = 0usize; let mut minv = [i32::MAX; 9]; let mut used = [false; 9];
        loop {
            used[j0] = true; let i0 = p[j0] as usize; let mut delta = i32::MAX; let mut j1 = 0usize;
            for j in 1..=n { if !used[j] {
                let cur = a[(i0 - 1) * 9 + j - 1] - u[i0] - v[j];
                if cur < minv[j] { minv[j] = cur; way[j] = j0 as i32; }
                if minv[j] < delta { delta = minv[j]; j1 = j; }
            } }
            for j in 0..=n { if used[j] { u[p[j] as usize] += delta; v[j] -= delta; } else { minv[j] -= delta; } }
            j0 = j1; if p[j0] == 0 { break; }
        }
        loop { let j1 = way[j0] as usize; p[j0] = p[j1]; j0 = j1; if j0 == 0 { break; } }
    }
    let mut matched = [-1i32; 9];
    for j in 1..=n { if p[j] != 0 { matched[p[j] as usize - 1] = j as i32 - 1; } }
    let mut assignments = [0i32; 8]; let mut total = 0i32;
    for i in 0..rows as usize { let j = matched[i]; assignments[i] = if j >= 0 && j < cols { j } else { -1 }; if assignments[i] >= 0 { total += values[2 + i * cols as usize + assignments[i] as usize]; } }
    let bytes = 4 * (rows as usize + 1);
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..rows as usize { store_i32_le(output, 4 * i, assignments[i]); }
    store_i32_le(output, 4 * rows as usize, total);
    bytes as i64
}
